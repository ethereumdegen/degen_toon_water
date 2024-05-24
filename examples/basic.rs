//! This example demonstrates the built-in 3d shapes in Bevy.
//! The scene includes a patterned texture and a rotation for visualizing the normals and UVs.

use bevy::core_pipeline::prepass::NormalPrepass;
use std::f32::consts::PI;

  
use bevy::asset::{AssetPath, LoadedFolder};
use bevy::core_pipeline::prepass::DepthPrepass;
//use bevy::pbr::{ExtendedMaterial, OpaqueRendererMethod};
use bevy::{gltf::GltfMesh, utils::HashMap};

//use bevy::gltf::Gltf;
 

use bevy::core_pipeline::bloom::BloomSettings;

use bevy::core_pipeline::tonemapping::Tonemapping;

use bevy::{core_pipeline::bloom::BloomCompositeMode, prelude::*};
 

 
use degen_toon_water::toonwater_material::{build_toon_water_material,  ToonWaterMaterial};
 
  
use degen_toon_water:: DegenToonWaterPlugin; 
use degen_toon_water::camera;


fn main() {
    App::new()


       // .insert_resource(BuiltVfxResource::default())
        .insert_resource(AssetLoadingResource::default())
        .insert_resource(FolderLoadingResource::default())
         .init_state::<LoadingState>()
        .add_plugins(DefaultPlugins.set(ImagePlugin::default_nearest()))
        //.add_plugins(bevy_obj::ObjPlugin)


        .add_plugins( DegenToonWaterPlugin )


       //  .add_systems(Update, update_load_folders)
 

        //.add_systems(OnEnter(LoadingState::FundamentalAssetsLoad), update_loading_shader_variant_manifest)
        //.add_systems(OnEnter(LoadingState::ShadersLoad), update_loading_magic_fx_variant_manifest)
        // .add_systems(OnEnter(LoadingState::Complete) , spawn_magic_fx) 

        
        .add_systems(Startup, setup)
        .add_systems(Update, camera::update_camera_look)
        .add_systems(Update, camera::update_camera_move)

        .run();
}
 

 



#[derive(Resource, Default)]
  struct AssetLoadingResource {
    texture_handles_map: HashMap<String, Handle<Image>>,
    //mesh_handles_map: HashMap<String, Handle<Mesh>>,
   // shader_variants_map: HashMap<String, Handle<ShaderVariantManifest>>,

   // magic_fx_variants_map: HashMap<String, Handle<MagicFxVariantManifest>>,

    
   //  animated_material_map: HashMap<String, Handle<AnimatedMaterial>>,
 
}


#[derive(Resource, Default)]
  struct FolderLoadingResource {
   

    textures_folder_handle: Handle<LoadedFolder>,
   // shadvars_folder_handle: Handle<LoadedFolder>,
  //  meshes_folder_handle: Handle<LoadedFolder>,

   //   magicfx_folder_handle: Handle<LoadedFolder>,

}

/*
#[derive(Event)]
pub enum LoadStateEvent {

    FundamentalAssetsLoaded 

}

*/

#[derive(States,Hash,Eq,PartialEq,Debug,Clone,Default)]
pub enum LoadingState {
    #[default]
    Init,
    FundamentalAssetsLoad,
    ShadersLoad,
    Complete

}



fn setup(
    mut commands: Commands,
    asset_server: ResMut<AssetServer>,
 

    mut folder_loading_resource: ResMut<FolderLoadingResource>,

    mut meshes: ResMut<Assets<Mesh>>,
    
    mut materials: ResMut<Assets<StandardMaterial>>,

    mut toon_water_materials: ResMut<Assets<ToonWaterMaterial>>,
     
) {
    /*

             Simulate our bevy asset loader with 'asset_loading_resource'
    */

    let base_color = Color::rgba(0.2,0.2,0.6,1.0);
    let emissive = Color::rgba(0.2,0.2,0.6,1.0);

    let surface_noise_texture_handle =  asset_server.load("textures/PerlinNoise.png");
    let surface_distortion_texture_handle =  asset_server.load("textures/WaterDistortion.png");
 
    let toon_water_material_handle = toon_water_materials.add( 
         build_toon_water_material (
            base_color,
            emissive,
            surface_noise_texture_handle,  
             surface_distortion_texture_handle,  
        ) );


 
    commands.spawn(PointLightBundle {
        point_light: PointLight {
            intensity: 2000.0,
            range: 100.,
            shadows_enabled: false,
            ..default()
        },
        transform: Transform::from_xyz(8.0, 16.0, 8.0),
        ..default()
    });

     commands.insert_resource(AmbientLight {
        color: Color::ANTIQUE_WHITE,
        brightness: 4000.0,
    });

    // ground plane
    commands.spawn((MaterialMeshBundle {
            mesh: meshes.add(Plane3d::default().mesh().size(50.0, 50.0)),
            material:  toon_water_material_handle,
            ..default()
        } ));





    commands.spawn(PbrBundle {
        mesh: meshes.add(Cuboid::new(555.0, 1.0, 555.0)),
        material: materials.add(StandardMaterial {
            base_color: Color::rgb(0.1,0.1,0.1).into(),
            ..Default::default()
        }),
        transform: Transform::from_xyz(0.0, -7.0, 0.0),
        ..default()
    });



    commands.spawn(PbrBundle {
        mesh: meshes.add(Cuboid::new(1.0, 7.0, 1.0)),
        material: materials.add(StandardMaterial {
            base_color: Color::rgb(0.6,0.6,0.6).into(),
            ..Default::default()
        }),
        transform: Transform::from_xyz(0.0, 0.2, 0.0),
        ..default()
    });


     commands.spawn(PbrBundle {
        mesh: meshes.add(Torus::new(5.0, 4.0 )),
        material: materials.add(StandardMaterial {
            base_color: Color::rgb(0.6,0.6,0.6).into(),
            ..Default::default()
        }),
        transform: Transform::from_xyz(0.0, -0.2, 0.0),
        ..default()
    });


   commands.spawn(PbrBundle {
        mesh: meshes.add(Torus::new(1.0, 1.0 )),
        material: materials.add(StandardMaterial {
            base_color: Color::rgb(0.6,0.6,0.6).into(),
            ..Default::default()
        }),
        transform: Transform::from_xyz(2.0, -0.6, 2.0),
        ..default()
    });


    commands.spawn((
        Camera3dBundle {
            camera: Camera {
                hdr: true, // 
                ..default()
            },
            tonemapping: Tonemapping::TonyMcMapface,
            transform: Transform::from_xyz(0.0, 6., 12.0)
                .looking_at(Vec3::new(0., 1., 0.), Vec3::Y),
            ..default()
        },
      //  BloomSettings::default(), // 2. Enable bloom for the camera

         BloomSettings::OLD_SCHOOL,
        DepthPrepass,
        NormalPrepass,  //needed for water ! 
       
    ));
}
 

 