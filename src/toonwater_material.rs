use bevy::prelude::*;
use bevy::reflect::TypePath;
use bevy::render::render_resource::*;

use bevy::pbr::{ExtendedMaterial, MaterialExtension, OpaqueRendererMethod};
use bevy::utils::HashMap;
 


pub type ToonWaterMaterial = ExtendedMaterial<StandardMaterial, ToonWaterMaterialBase>;


pub fn build_toon_water_material(
   	base_color: Color,
    emissive: Color,
    surface_noise_texture_handle: Handle<Image>,
    surface_distortion_texture_handle: Handle<Image>,
    ) ->   ToonWaterMaterial {

  
    ExtendedMaterial {
                     base: StandardMaterial {
			            base_color,
			            emissive,
			            opaque_render_method: OpaqueRendererMethod::Auto,
			            alpha_mode: AlphaMode::Blend,
			            double_sided: true,
			            cull_mode: None,
			            ..Default::default()
			        },
			        extension: ToonWaterMaterialBase {
			          //  base_color_texture: Some(texture_handle),
			            custom_uniforms: ToonWaterMaterialUniforms::default(),
			            surface_noise_texture: Some(surface_noise_texture_handle),
			            surface_distortion_texture: Some(surface_distortion_texture_handle),
			            //depth_texture: None,
			            //normal_texture: None,
			        },
                }

      
}

//pub type AnimatedMaterialExtension = ExtendedMaterial<StandardMaterial, AnimatedMaterial>;
pub type ToonWaterMaterialBundle = MaterialMeshBundle<ToonWaterMaterial >;

#[derive(Clone, ShaderType, Debug)]
pub struct ToonWaterMaterialUniforms {

	pub depth_gradient_shallow: Color,
    pub depth_gradient_deep: Color,
    pub depth_max_distance: f32,
    pub foam_color: Color,
    pub surface_noise_scroll: Vec2,
    pub surface_noise_cutoff: f32,
    pub surface_distortion_amount: f32,
    pub foam_max_distance: f32,
    pub foam_min_distance: f32,

 
}
impl Default for ToonWaterMaterialUniforms {
    fn default() -> Self {
        Self {
		    depth_gradient_shallow: Color::rgba(0.4,0.4,0.8,1.0),
            depth_gradient_deep: Color::rgba(0.2,0.2,0.4,1.0),
            depth_max_distance: 10.0,
            foam_color: Color::rgba(0.9,0.9,0.9,1.0),
            surface_noise_scroll: Vec2::new(1.0,1.0),
            surface_noise_cutoff: 0.2,
            surface_distortion_amount: 1.0,
            foam_max_distance: 1.0,
            foam_min_distance: 0.0,
        }
    }
}

#[derive(Asset, AsBindGroup, TypePath, Debug, Clone, Default)]
pub struct ToonWaterMaterialBase {
   #[uniform(20)]
    pub custom_uniforms: ToonWaterMaterialUniforms,
  //  #[texture(21)]
  //  #[sampler(22)]
  //  pub base_color_texture: Option<Handle<Image>>,
    #[texture(23)]
    #[sampler(24)]
    pub surface_noise_texture: Option<Handle<Image>>,
    #[texture(25)]
    #[sampler(26)]
    pub surface_distortion_texture: Option<Handle<Image>>,
    //#[texture(27)]
    //#[sampler(28)]
   // pub depth_texture: Option<Handle<Image>>,
    //#[texture(29)]
   // #[sampler(30)]
   // pub normal_texture: Option<Handle<Image>>,
}

impl MaterialExtension for ToonWaterMaterialBase {
    fn fragment_shader() -> ShaderRef {
        "shaders/toonwater.wgsl".into()
    }

    fn deferred_fragment_shader() -> ShaderRef {
        "shaders/toonwater.wgsl".into()
    }
}
