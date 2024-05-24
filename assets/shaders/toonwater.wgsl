 
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

@group(2) @binding(25)
var surface_distortion_texture: texture_2d<f32>;

 

 
//should consider adding vertex painting to this .. need another binding of course.. performs a color shift 

 
//@fragment
//fn fragment(
//    mesh: VertexOutput,
//    @builtin(front_facing) is_front: bool,
  
 


@fragment
fn fragment(
   // @builtin(position) frag_coord: vec4<f32>,
     mesh: VertexOutput,
) -> @location(0) vec4<f32> {
    let uv = mesh.uv  ;
    
 

    let sample_index = 0u;
    let depth = prepass_utils::prepass_depth(mesh.position,sample_index);
    let prepass_normal = prepass_utils::prepass_normal(mesh.position,sample_index);
 
    //let depth_linear = -(view.view_proj[3][2] / (depth - view.view_proj[2][2])); 
    let depth_diff = mesh.position.z - depth ;

    let water_depth_diff = saturate(depth_diff / toon_water_uniforms.depth_max_distance);
    let water_color = mix(toon_water_uniforms.depth_gradient_shallow, toon_water_uniforms.depth_gradient_deep, water_depth_diff);

    let normal = prepass_normal ; //textureLoad(normal_texture, vec2<i32>(frag_coord.xy), 0).xyz;
    let normal_dot = saturate(dot(normal,  normalize(mesh.world_normal) ));
    let foam_distance = mix(toon_water_uniforms.foam_max_distance, toon_water_uniforms.foam_min_distance, normal_dot);  
    let foam_depth_diff = saturate(depth_diff / foam_distance);

    let surface_noise_cutoff = foam_depth_diff * toon_water_uniforms.surface_noise_cutoff;
    
    let distort_uv = uv * vec2<f32>(textureDimensions(surface_distortion_texture)); 
    let distort_sample = (textureLoad(surface_distortion_texture, vec2<i32>(distort_uv), 0).rg * 2.0 - 1.0) * toon_water_uniforms.surface_distortion_amount;


    let time_base = globals.time % 1.0;

    let noise_uv = vec2<f32>(
        (uv.x + time_base * toon_water_uniforms.surface_noise_scroll.x) + distort_sample.x, 
        (uv.y + time_base * toon_water_uniforms.surface_noise_scroll.y) + distort_sample.y
    );
    let surface_noise_sample = textureLoad(surface_noise_texture, vec2<i32>(noise_uv * vec2<f32>(textureDimensions(surface_noise_texture))), 0).r;
    
    let surface_noise = smoothstep(surface_noise_cutoff - 0.01, surface_noise_cutoff + 0.01, surface_noise_sample);

    var surface_noise_color = toon_water_uniforms.foam_color;
    surface_noise_color.a *= surface_noise;

    var color = alpha_blend(surface_noise_color, water_color);


  //  color = vec4(water_depth_diff ,water_depth_diff ,water_depth_diff ,1.0);
    return color;
}

fn alpha_blend(top: vec4<f32>, bottom: vec4<f32>) -> vec4<f32> {
    let color = top.rgb * top.a + bottom.rgb * (1.0 - top.a);
    let alpha = top.a + bottom.a * (1.0 - top.a);
    return vec4<f32>(color, alpha);  
}


 

@vertex
fn vertex(
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    // other attributes...
) -> VertexOutput {
    var out: VertexOutput;
   // out.clip_position = uniforms.view_proj * vec4<f32>(position, 1.0);
  //  out.world_position = uniforms.model * vec4<f32>(position, 1.0);
  //  out.uv = uv;
  //  out.view_normal = normalize(uniforms.view * uniforms.model * vec4<f32>(normal, 0.0)).xyz;
    return out;
}