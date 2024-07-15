
use bevy::render::render_asset::RenderAssetUsages;
use bevy::render::texture::{CompressedImageFormats, ImageFormat, ImageSampler, ImageType};
use toonwater_material::ToonWaterMaterial;
use std::io::{Cursor, Read};
use bevy::asset::load_internal_asset;
use bevy::prelude::*;
use bevy::render::texture::ImageLoader;
pub mod toonwater_material;
pub mod camera;







pub struct DegenToonWaterPlugin;
 
impl Plugin for DegenToonWaterPlugin {
    fn build(&self, app: &mut App) {

         load_internal_asset!(
            app,
            TOON_WATER_SHADER_HANDLE,
            "assets/toonwater.wgsl",
            Shader::from_wgsl
        );

          

            // Load the image data into a byte vector
        

        // Load the image from the cursor
        let noise_image = Image::from_buffer(
            include_bytes!("assets/PerlinNoise.png"), 
            ImageType::Format(ImageFormat::Png),
            CompressedImageFormats::empty(), 
            false,
            ImageSampler::default(),
            RenderAssetUsages::default() 
        ).unwrap();

        let distortion_image = Image::from_buffer(
            include_bytes!("assets/WaterDistortion.png"), 
            ImageType::Format(ImageFormat::Png),
            CompressedImageFormats::empty(), 
            false,
            ImageSampler::default(),
            RenderAssetUsages::default() 
        ).unwrap();

 

        let mut images = app.world_mut().resource_mut::<Assets<Image>>();
  
        images.insert(& DEFAULT_NOISE_MAP_HANDLE, noise_image );

        images.insert(& DEFAULT_DISTORTION_MAP_HANDLE, distortion_image );
   

         
        app
           
            .add_plugins(MaterialPlugin::<toonwater_material::ToonWaterMaterial > {

                 prepass_enabled: false,
                ..default() 
            })

            .add_systems(Update, update_material_coord_scale)
             
            ;

    }
}

pub(crate) const TOON_WATER_SHADER_HANDLE: Handle<Shader> =
    Handle::weak_from_u128(4_443_976_952_151_597_127);



 
pub const DEFAULT_NOISE_MAP_HANDLE: Handle<Image> =
    Handle::weak_from_u128(6_154_765_653_326_313_901);


pub const DEFAULT_DISTORTION_MAP_HANDLE: Handle<Image> =
    Handle::weak_from_u128(6_441_765_653_326_404_902);

 

 fn update_material_coord_scale (


    material_query: Query < ( &Handle<ToonWaterMaterial>, &GlobalTransform)  >,
    mut materials: ResMut<Assets<ToonWaterMaterial>>
){

    for (mat_handle, global_xform) in material_query.iter(){



        if let Some(  material) = materials.get_mut( mat_handle ){
        
            let translation = global_xform.translation();
            let scale = global_xform.to_scale_rotation_translation().0;


            let x = translation.x;
            let y = translation.z;



            let coord_offset = Vec2::new(x,y);
            let coord_scale = Vec2::new(scale.x as f32, scale.z as f32);

         
            material.extension.custom_uniforms.coord_offset = coord_offset;
            material.extension.custom_uniforms.coord_scale = coord_scale;


        }

    }

 }