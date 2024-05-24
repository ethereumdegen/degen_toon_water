
use bevy::prelude::*;
pub mod toonwater_material;
pub mod camera;


pub struct DegenToonWaterPlugin;
 
impl Plugin for DegenToonWaterPlugin {
    fn build(&self, app: &mut App) {
         
        app
           
            .add_plugins(MaterialPlugin::<toonwater_material::ToonWaterMaterial > {

                 prepass_enabled: false,
                ..default() 
            })
             
            ;

    }
}

