 
 #import bevy_pbr::mesh_functions  mesh_position_local_to_clip
  #import bevy_pbr::mesh_functions  mesh_position_local_to_world
  #import bevy_pbr::mesh_bindings   mesh

 #import bevy_pbr::{
    mesh_view_bindings::globals, 
    forward_io::{VertexOutput, FragmentOutput}, 
    pbr_fragment::pbr_input_from_standard_material,
      pbr_functions::{alpha_discard, apply_pbr_lighting, main_pass_post_lighting_processing},
    pbr_types::STANDARD_MATERIAL_FLAGS_UNLIT_BIT,
      pbr_deferred_functions::deferred_output
}
 #import bevy_pbr::mesh_functions
  #import bevy_pbr::prepass_utils


 #import bevy_pbr::mesh_view_bindings view

#import bevy_pbr::view_transformations::{
position_clip_to_world,
sition_view_to_clip, 
position_clip_to_view,
position_view_to_world,
depth_ndc_to_view_z
} 



struct StandardMaterial {
    time: f32,
    base_color: vec4<f32>,
    emissive: vec4<f32>,
    perceptual_roughness: f32,
    metallic: f32,
    reflectance: f32,
    // 'flags' is a bit field indicating various options. u32 is 32 bits so we have up to 32 options.
    flags: u32,
    alpha_cutoff: f32,
};
 
 struct ToonWaterMaterialUniforms {
    depth_gradient_shallow: vec4<f32>,
    depth_gradient_deep: vec4<f32>,
    depth_max_distance: f32,
    foam_color: vec4<f32>,
    surface_noise_scroll: vec2<f32>,
    surface_noise_cutoff: f32,
    surface_distortion_amount: f32,
    foam_max_distance: f32,
    foam_min_distance: f32,
    noise_map_scale: f32, 

    coord_offset: vec2<f32>,
    coord_scale: vec2<f32>,
};
 

 


@group(2) @binding(20)
var<uniform> toon_water_uniforms: ToonWaterMaterialUniforms;
 
 //@group(2) @binding(21)
//var base_color_texture: texture_2d<f32>;

@group(2) @binding(23)
var surface_noise_texture: texture_2d<f32>;
@group(2) @binding(24)
var surface_noise_sampler: sampler;


@group(2) @binding(25)
var surface_distortion_texture: texture_2d<f32>;
@group(2) @binding(26)
var surface_distortion_sampler: sampler;
 

 
//should consider adding vertex painting to this .. need another binding of course.. performs a color shift 

 
//@fragment
//fn fragment(
//    mesh: VertexOutput,
//    @builtin(front_facing) is_front: bool,
  
 

 // i want to make the foam smaller overall and also more concentrated where there is depth 
//https://github.com/bevyengine/bevy/blob/7d843e0c0891545ec6cc0131398b0db6364a7a88/crates/bevy_pbr/src/prepass/prepass.wgsl#L4


//https://github.com/bevyengine/bevy/blob/7d843e0c0891545ec6cc0131398b0db6364a7a88/crates/bevy_pbr/src/render/view_transformations.wgsl#L101
    // i really need world position z !


@fragment
fn fragment(
     
     mesh: VertexOutput,
) -> @location(0) vec4<f32> {
    let uv = mesh.uv  ;

    
  //  var world_position: vec4<f32> = mesh.world_position;
    let scaled_uv =  uv_to_coord(mesh.uv) * toon_water_uniforms.noise_map_scale * 0.02 ;
    
    //saturate clamps between 0 and 1 
 
    let depth = prepass_utils::prepass_depth(mesh.position,0u);
    let prepass_normal = prepass_utils::prepass_normal(mesh.position,0u);



            
     //this is how the frag_depth (buffer) is written to by other things 
     //this seems to be correct 
   let water_surface_world_pos =      mesh.world_position   ;  
 
    
    //this is correct 
   let screen_position_uv = (mesh.position.xy + vec2<f32>(0.5,0.5) ) /   view.viewport.zw ;
     

 

   //  view.viewport.zw is width and height of viewport 


     let depth_buffer_view = reconstruct_view_space_position ( screen_position_uv, depth );

     //this works !! 
     let depth_buffer_world = position_view_to_world( depth_buffer_view );

    
     

   //this should show the distance of any given obstruction to the surface of the water 
   //it is good enough 
  let depth_diff =  1.0 -    ( -1.0 *  (depth_buffer_world. y - water_surface_world_pos.y) / toon_water_uniforms.depth_max_distance   ) ;

    // let depth_diff =  ( -1.0 *  water_surface_world_pos.y  - depth_buffer_world. y  ) ;



    let water_depth_diff = 1.0 - saturate( depth_diff );
 
    let water_color = mix(toon_water_uniforms.depth_gradient_shallow, toon_water_uniforms.depth_gradient_deep, water_depth_diff);

   // normal dot is a  grayscale map showing stuff under the water , to make our foam stand out on logs but not on shore 
    let normal_dot = saturate(dot(prepass_normal,  normalize(mesh.world_normal) ))  ;


        
    let water_depth_diff_foam =   saturate(   depth_diff    );

   // let normal_dot_dampen_factor = 0.0;

    //let normal_dot_contribution_factor = 1.0;

    let foam_factor_from_normal =   saturate( 1.0  - normal_dot) ;

    //foam is reduced the deeper the underwater obstruction is 
    let foam_factor = saturate(  mix( 0.0 ,  foam_factor_from_normal  ,  water_depth_diff_foam  ) );

    let foam_amount = mix(toon_water_uniforms.foam_min_distance, toon_water_uniforms.foam_max_distance,   foam_factor);  
    
    //this means that an obstruction with a perpendicular normal to the water surface will act like its SUPER close to the water , producing more foam 
   // let foam_amount =   saturate((water_depth_diff ) / foam_normal_factor);

    //foam depth is small where there is something right under the water 


    //if foam depth diff is very white (an obstruction under surface) then we should use a SMALLER cutoff to show more foam there 
     
    let surface_noise_cutoff = toon_water_uniforms.surface_noise_cutoff - (  toon_water_uniforms.surface_noise_cutoff*    foam_amount  );

      //    let distort_uv_scale = 1.0;

 
   let distort_sample = textureSample(surface_distortion_texture, surface_distortion_sampler, scaled_uv   )   ;


    //distort sample is messing me up ! 

    let time_base =  ( globals.time  ) * 1.0  ;

    let distorted_plane_uv = scaled_uv + (distort_sample.rg * toon_water_uniforms. surface_distortion_amount);

    var noise_uv = vec2<f32>(
        (distorted_plane_uv.x + (time_base * toon_water_uniforms.surface_noise_scroll.x)) %1.0 ,
        (distorted_plane_uv.y + (time_base * toon_water_uniforms.surface_noise_scroll.y))  %1.0 
    );

     var noise_uv_alt = vec2<f32>(  //this is out of sync time-wise which makes a nice effect when combined
        (distorted_plane_uv.x + (time_base *1.1 * toon_water_uniforms.surface_noise_scroll.x)) % 1.0 ,
        (distorted_plane_uv.y + (time_base  *1.1 * toon_water_uniforms.surface_noise_scroll.y))  %1.0 
    );
    

   let distortion_noise_sample = textureSample(surface_distortion_texture, surface_distortion_sampler, noise_uv_alt    )   ;

   let surface_noise_sample = textureSample(surface_noise_texture, surface_noise_sampler, noise_uv    )   ;


   let smoothstep_tolerance_band = 0.01 ; //controls foam edge sharpness

   let combined_noise_sample =  surface_noise_sample.r * distortion_noise_sample.g * 2.0 ;

     // this is our foam 
    var surface_noise = smoothstep(surface_noise_cutoff -  smoothstep_tolerance_band, surface_noise_cutoff +  smoothstep_tolerance_band ,    combined_noise_sample );



      // only do surface noise - special bands ? 







  //let surface_noise =  step( surface_noise_cutoff, surface_noise_sample.r);









    // ---   fog cloud noise 

 

          let fog_cloud_time_base = ( globals.time   * 0.01 )   % 1.0 ;

          let fog_cloud_world_pos_offset = vec2<f32>(   abs(mesh.world_position .x +  globals.time)  ,   abs(mesh.world_position .z ) ) * 0.01 ;
          let fog_cloud_scroll =  vec2<f32>( fog_cloud_time_base  ,  fog_cloud_time_base  )  ;

            //aso need sine wave time shit on this uv input 
        var  fog_cloud_noise_uv = fog_cloud_world_pos_offset + fog_cloud_scroll ; 
        
         fog_cloud_noise_uv.x = fog_cloud_noise_uv.x % 1.0;  
         fog_cloud_noise_uv.y = fog_cloud_noise_uv.y % 1.0;  

        let fog_cloud_sample = textureSample(surface_distortion_texture, surface_distortion_sampler, fog_cloud_noise_uv)  ;


       
         let highlight_color = vec4<f32>(1.0, 1.0, 1.0, 1.0);
         let shadow_color = vec4<f32>(0.5,0.5,0.5, 1.0);
       
         let fog_cloud_color = mix(shadow_color, highlight_color, fog_cloud_sample.r  );

        
    // ---------
            // sun band 

    let world_position = mesh.world_position.xyz;
    let camera_position = view.world_position;


   // let view_direction = normalize(world_position - camera_position);

     //let sun_direction  = normalize( vec3<f32>(0.3,  0.3, 0.3) ) ;  // for now ... 
  
    // let sun_band_direction = normalize (mix( view_direction , sun_direction , 0.5 ));

    let sun_band =  calculate_sun_band( world_position, camera_position    )    ;

    




// -----------




  //apply the foam ! ----

  surface_noise *= fog_cloud_color .r ;

  surface_noise *= (sun_band + 0.05 ); 
  // only render the foam (surface noise)   in 'sun bands'  which are diagonal bands projects out of view camera  






    var surface_noise_color = toon_water_uniforms.foam_color;
    surface_noise_color.a *= surface_noise;

    var color = alpha_blend(surface_noise_color, water_color);
//----

    
    
    //apply the fog clouds 
     color *= fog_cloud_color  ; 







 //  color = vec4( depth_diff,depth_diff,depth_diff ,1.0);

 // color = vec4<f32>(depth_buffer_world.x, depth_buffer_world.y, depth_buffer_world.z, 1.0);


  //  color = vec4(surface_noise   ,surface_noise   , surface_noise ,1.0);
 
 //  return vec4( sun_band , 0.0,0.0,1.0   );

      return color ; 
}

// Camera-based sun reflection bands compatible with Bevy View structure
fn calculate_sun_band(world_position: vec3<f32>, camera_position: vec3<f32>) -> f32 {
    let band_frequency = 2.0;  // Controls how many bands appear
    let band_sharpness = 5.0;  // Controls how sharp the bands are
    let band_angle = 0.3;      // Controls the angle of the bands (0.0-1.0)
    
    // Calculate direction from camera to fragment
    let view_direction = normalize(world_position - camera_position);
    
    // Extract camera basis vectors from world_from_view matrix
    // In Bevy's View structure, world_from_view is the camera's transform
    
    // Forward vector (negative z in view space becomes world space)
    let camera_forward = -normalize(vec3<f32>(
        view.world_from_view[0][2],
        view.world_from_view[1][2],
        view.world_from_view[2][2]
    ));
    
    // Right vector (positive x in view space becomes world space)
    let camera_right = normalize(vec3<f32>(
        view.world_from_view[0][0],
        view.world_from_view[1][0],
        view.world_from_view[2][0]
    ));
    
    // Up vector (positive y in view space becomes world space)
    let camera_up = normalize(vec3<f32>(
        view.world_from_view[0][1],
        view.world_from_view[1][1],
        view.world_from_view[2][1]
    ));
    
    // Create a sun direction that's offset from camera view
    // This creates a dynamic sun direction that moves with the camera
    // but stays at a consistent angle from the view direction
    let sun_direction = normalize(
        camera_forward + 
        camera_right * cos(globals.time * 0.1) * band_angle + 
        camera_up * sin(globals.time * 0.1) * band_angle
    );
    
    // Fixed up-facing water normal
    let water_normal = vec3<f32>(0.0, 1.0, 0.0);
    
    // Calculate reflection vector
    let reflection_vector = reflect(view_direction, water_normal);
    
    // Create bands based on dot product between reflection and sun
    let alignment = dot(reflection_vector, sun_direction) * 0.5 + 0.5; // Remap to 0-1
    
    // Create repeating bands
    let bands = sin(alignment * band_frequency * 3.14159) * 0.5 + 0.5;
    
    // Make bands sharper with pow function
    let sharp_bands = pow(bands, band_sharpness);
    
    return sharp_bands;
}



/*
fn calculate_sun_band(view_direction: vec3<f32>,  sun_direction: vec3<f32>) -> f32 {
    let sun_band_sharpness = 32.0; // Higher value = sharper band
    let sun_band_brightness = 1.0;

      // Use a fixed up-facing normal (0,1,0) for flat water
    let water_normal = vec3<f32>(0.0, 1.0, 0.0);

    
    // Calculate reflection vector (how view direction reflects off water surface)
    // Note: view_direction should point FROM the camera TO the surface
    // If your view_direction is the opposite, you'll need to negate it first
    let reflection_vector = reflect(view_direction, water_normal);
    
    // Calculate how closely this reflection aligns with the sun direction
    let sun_alignment = max(0.0, dot(reflection_vector, sun_direction));
    
    // Apply a power function to make the band sharper
    let sun_band = pow(sun_alignment, sun_band_sharpness) * sun_band_brightness;
    
    return sun_band;
}*/


fn alpha_blend(top: vec4<f32>, bottom: vec4<f32>) -> vec4<f32> {
    let color = top.rgb * top.a + bottom.rgb * (1.0 - top.a);
    let alpha = top.a + bottom.a * (1.0 - top.a);
    return vec4<f32>(color, alpha);  
}

fn uv_to_coord(uv: vec2<f32>) -> vec2<f32> {
  return toon_water_uniforms.coord_offset + (uv * toon_water_uniforms.coord_scale);
}

  

fn screen_to_clip(screen_coord: vec2<f32>, depth: f32) -> vec4<f32> {
    let ndc_x = screen_coord.x * 2.0 - 1.0;
    let ndc_y = screen_coord.y * 2.0 - 1.0;
    let ndc_z = depth * 2.0 - 1.0;
    return vec4<f32>(ndc_x, ndc_y, ndc_z, 1.0);
}


  fn reconstruct_view_space_position( uv: vec2<f32>, depth: f32) -> vec3<f32> {
    let clip_xy = vec2<f32>(uv.x * 2.0 - 1.0, 1.0 - 2.0 * uv.y);
    let t = view.view_from_clip * vec4<f32>(clip_xy, depth, 1.0);
    let view_xyz = t.xyz / t.w;
    return view_xyz;
}



fn clip_to_view(clip_pos: vec4<f32>) -> vec3<f32> {
    // Transform from clip space to view space using the inverse projection matrix
    let view_space = view.view_from_clip * clip_pos;
    let view_space_pos = view_space.xyz / view_space.w;

    // Transform from view space to world space using the inverse view matrix
  //  let world_space = view.inverse_view * vec4<f32>(view_space_pos, 1.0);
    return view_space_pos.xyz;
}

