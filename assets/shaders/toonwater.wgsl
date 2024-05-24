 
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


// #import bevy_pbr::mesh_view_bindings view




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
  
 


@fragment
fn fragment(
     //@builtin(position) frag_coord: vec4<f32>,
      //@builtin(position) frag_coord: vec4<f32>,
     mesh: VertexOutput,
) -> @location(0) vec4<f32> {
    let uv = mesh.uv  ;
    
    //saturate clamps between 0 and 1 
 
    let depth = prepass_utils::prepass_depth(mesh.position,0u);
    let prepass_normal = prepass_utils::prepass_normal(mesh.position,0u);
        
   // let normalized_water_plane_depth = mesh.position.z  ;  //doesnt matter !! 
 
    let depth_diff =  saturate(   depth   )  ;

    let water_depth_diff = saturate(depth_diff / toon_water_uniforms.depth_max_distance);
 
    let water_color = mix(toon_water_uniforms.depth_gradient_shallow, toon_water_uniforms.depth_gradient_deep, water_depth_diff);

   // normal dot is a  grayscale map showing stuff under the water , to make our foam stand out on logs but not on shore 
    let normal_dot = saturate(dot(prepass_normal,  normalize(mesh.world_normal) ))  ;



        
    let water_depth_diff_foam =   saturate(   depth_diff * 3.0   );
    let foam_factor = saturate(  mix( water_depth_diff_foam ,    saturate(water_depth_diff_foam / (0.3+normal_dot))   , 0.3  )  );

    let foam_amount = mix(toon_water_uniforms.foam_min_distance, toon_water_uniforms.foam_max_distance,   foam_factor);  
    
    //this means that an obstruction with a perpendicular normal to the water surface will act like its SUPER close to the water , producing more foam 
   // let foam_amount =   saturate((water_depth_diff ) / foam_normal_factor);

    //foam depth is small where there is something right under the water 


    //if foam depth diff is very white (an obstruction under surface) then we should use a SMALLER cutoff to show more foam there 
    /*let surface_noise_cutoff = mix( 
     toon_water_uniforms.surface_noise_cutoff ,  
     toon_water_uniforms.surface_noise_cutoff * 0.1,   
      foam_amount

        ); */ //make foam depth diff addd to this 
    let surface_noise_cutoff = toon_water_uniforms.surface_noise_cutoff - (  toon_water_uniforms.surface_noise_cutoff*    foam_amount  );

      //    let distort_uv_scale = 1.0;

 
   let distort_sample = textureSample(surface_distortion_texture, surface_distortion_sampler, uv   )   ;


    //distort sample is messing me up ! 

    let time_base =  ( globals.time  ) * 1.0  ;

    let distorted_plane_uv = uv + (distort_sample.rg * toon_water_uniforms. surface_distortion_amount);
    var noise_uv = vec2<f32>(
        (distorted_plane_uv.x + (time_base * toon_water_uniforms.surface_noise_scroll.x)) %1.0 ,
        (distorted_plane_uv.y + (time_base * toon_water_uniforms.surface_noise_scroll.y))  %1.0 
    );
    

      
   let surface_noise_sample = textureSample(surface_noise_texture, surface_noise_sampler, noise_uv    )   ;

     
    let surface_noise = smoothstep(surface_noise_cutoff - 0.01, surface_noise_cutoff + 0.01,   surface_noise_sample.r);

  //let surface_noise =  step( surface_noise_cutoff, surface_noise_sample.r);

    var surface_noise_color = toon_water_uniforms.foam_color;
    surface_noise_color.a *= surface_noise;

    var color = alpha_blend(surface_noise_color, water_color);

    //color = vec4(  water_depth_diff  ,  water_depth_diff  , water_depth_diff  ,1.0);

  // color = vec4(surface_noise_sample.r  ,surface_noise_sample.g  , surface_noise_sample.b  ,1.0);
  //  color = vec4(surface_noise   ,surface_noise   , surface_noise ,1.0);
    return color;
}

fn alpha_blend(top: vec4<f32>, bottom: vec4<f32>) -> vec4<f32> {
    let color = top.rgb * top.a + bottom.rgb * (1.0 - top.a);
    let alpha = top.a + bottom.a * (1.0 - top.a);
    return vec4<f32>(color, alpha);  
}


  