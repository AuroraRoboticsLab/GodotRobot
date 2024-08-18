/*
  A 9m diameter large human landing system (HLS) spaceship.

  by Dr. Orion Lawlor, lawlor@alaska.edu, 2024-08-17 (Public Domain)
*/

// File units: meters
//$fs=0.2; $fa=3; // smoother
$fs=0.4; $fa=6; // lower poly

// Outside diameter of ship
shipOD=9.0;
shipR=shipOD/2;

// Overall height of ship
shipZ=50.0;

shipZengine=5; // height of engine bay (raptor is 4.6 meters according to spaceX)

shipZogive=39; // nosecone ogive starts at this height
shipRogive=20; // tweaked to give a top docking port

shipLegs=4; // mostly to fit around elevator (6 also plausible)

shipbulkheadS=[1,1,0.5]; // Z squash on bulkheads


shipZelevator=30.0; // Z height of bottom of elevator
shipZhab=34.0; // Z height of bottom of hab area
shipRairlock=1.5; // radius of internal airlocks

module ship_half_2D()
{
    difference() {
        union() {
            // main tube body
            square([shipR,shipZogive]);
            
            // ogive nosecone
            intersection() {
                square([shipR,shipZ]);
                translate([shipR-shipRogive,shipZogive])
                    circle(r=shipRogive);
            }
        }
        
        // chop out engine bay
        baywall=0.2;
        difference() {
            square([shipR-baywall, shipZengine]);
            
            translate([0,shipZengine+1])
            scale([shipbulkheadS[0],shipbulkheadS[2]])
                circle(r=shipR,$fn=16);
        }
        
        // chop out elevator bay space
        translate([0,shipZelevator-0.3])
        difference() {
            square([shipR-baywall, shipZhab-shipZelevator]);
            
            // curved pressure bulkhead under hab
            translate([0,shipZhab-shipZelevator+1.5])
            scale([shipbulkheadS[0],shipbulkheadS[2]])
                circle(r=shipR);
        }
        
    }
}


// 3D ship model
module ship_solid_3D()
{
    rotate_extrude(convexity=4)
        ship_half_2D();
    
    // space for airlocks up to habs
    translate([0,0,shipZelevator-1])
        for (side=[-1,+1]) translate([side*(shipR-shipRairlock-0.1),0])
            cylinder(r=shipRairlock,h=6);
}

// Put children at each leg center, at base of skirt
//   X faces out from leg
module ship_leg_centers() {
    for (leg=[0:shipLegs-1])
        rotate([0,0,45+360/shipLegs*leg])
            translate([shipR,0,0])
                children();
}

// create leg member between these two points
module ship_leg_beam(p1,p2,r=0.1) {
    $fn=6; // save polygons, look a bit more constructed
    hull() {
        buff=2.0;  buffN=0.2;
        translate(p1) sphere(r=r);
        translate(p1*(1.0-buffN)+p2*buffN) sphere(r=buff*r);
        translate(p2*(1.0-buffN)+p1*buffN) sphere(r=buff*r);
        translate(p2) sphere(r=r);
    }
}

// fold-out leg inspired by apollo
module ship_leg() {
    start=[0,0,0.1]; // where leg attaches to skirt
    out=[7,0,-1]; // where leg hits the ground
    up =[0,0,8]; // where leg attaches to tank
    
    mid=out*0.5+up*0.5; // midpoint stabilizers
    
    sideL=[-0.3,1,5];
    sideR=[sideL[0],-sideL[1],sideL[2]];
    
    lowL=[-0.5,2,start[2]];
    lowR=[lowL[0],-lowL[1],lowL[2]];
    outH = out*0.5 + mid*0.5; // where horizontal stabilizers attach
    
    ship_leg_beam(mid,out);
    ship_leg_beam(mid,up);

    // tensile members
    tensileR=0.05;
    ship_leg_beam(start,mid,tensileR);
    ship_leg_beam(sideL,mid,tensileR);
    ship_leg_beam(sideR,mid,tensileR);
    ship_leg_beam(lowL,outH,tensileR);
    ship_leg_beam(lowR,outH,tensileR);
    
    // foot:
    //   landing mass: 200 tonnes with safety factor
    //   landing weight: 324 kN
    //   regolith strength: 10 kPa compressive
    //   required surface area: 32 square meters
    //   area per foot: 8 square meters
    //   radius per foot: 1.6 meters
    translate(out-[0,0,0.3]) cylinder(r1=1.0,r2=1.8,h=0.3);
    
}

// notch for leg to fold into during launch
module ship_leg_space() {
    rotate([0,10,0])
        cylinder(d=0.4,h=1.3);
}

// ship with landing legs
module ship_legged() {
    difference() {
        ship_solid_3D();
        ship_leg_centers() ship_leg_space();
    }
    //ship_leg_centers() ship_leg();
}

cageXelevator=3.5; // width of elevator cage
cageYelevator=3; // front-back of elevator cage
cageZelevator=2.5; // height of elevator cage
cageclearance=0.3;

shipRelevator=shipR+0.1; // distance of elevator from ship skin

// X-Z section of elevator
module elevator2D() {
    translate([-cageXelevator/2,0])
        square([cageXelevator,cageZelevator]);
}

// ship with elevator door open
module ship_elevator() {
    difference() {
        ship_solid_3D();
        
        translate([0,shipRelevator,shipZelevator])
            rotate([90,0,0])
                linear_extrude(height=2*cageYelevator,center=true)
                    offset(r=cageclearance) // clearance around cage
                        elevator2D();

    }
}

// elevator cage, exterior only (texture for graphics, colliders for shape)
module elevator_cage() {
    translate([-cageXelevator/2,shipRelevator,-1])
        cube([cageXelevator,cageYelevator,cageZelevator]);
}

// elevator hoist, on sliding I-beam
module elevator_hoist() {
    z=shipZelevator+cageZelevator+cageclearance/2;
    dx=0.1; // width of beam
    dz=0.3; // height of beam
    dy=6.0; // length of sliding beam
    translate([0,shipRelevator,z])
        cube([dx,dy,dz],center=true);
    translate([0,0,z+dz])
        cube([2*dx,2*shipR-0.1,dz],center=true);
}

ship_elevator();
elevator_hoist();

// legs separate, since they're not smooth shaded
//ship_leg_centers() ship_leg();

//elevator_cage();

