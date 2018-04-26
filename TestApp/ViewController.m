//
//  ViewController.m
//  TestApp
//
//  Created by Bern on 23.04.2018.
//  Copyright © 2018 Bern. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <ARSCNViewDelegate, ARSessionDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;
@property (nonatomic, strong) SCNNode *arrow;
@property (nonatomic, strong) SCNNode *arrowBase;

@end

    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set the view's delegate
    self.sceneView.delegate = self;
    
    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
    
    // Create a new scene
    SCNScene *scene = [[SCNScene alloc] init];

    // Set the scene to the view
    self.sceneView.scene = scene;
    for (int i=0; i<3; i++) {
        [self addObject];
    }
    [self addArrow];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Create a session configuration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];

    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration];
    self.sceneView.session.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - ARSCNViewDelegate

/*
// Override to create and configure nodes for anchors added to the view's session.
- (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
    SCNNode *node = [SCNNode new];
 
    // Add geometry to the node...
 
    return node;
}
*/

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

- (float)randomValue {
    return (float)arc4random() / (float)UINT32_MAX * -3 + 1.5;
}

- (void)addObject {
    SCNNode *wrapperNode = [SCNNode nodeWithGeometry:[SCNBox boxWithWidth:0.1 height:0.1 length:0.1 chamferRadius:0]];
    wrapperNode.name = @"object";
    wrapperNode.position = SCNVector3Make([self randomValue], [self randomValue], [self randomValue]);
    [self.sceneView.scene.rootNode addChildNode:wrapperNode];
}

- (void)addArrow {
    SCNNode *arrowBaseNode = [SCNNode nodeWithGeometry:[SCNSphere sphereWithRadius:0.01]];
    
    arrowBaseNode.position = SCNVector3Make(0, 0, -0.2);
    arrowBaseNode.geometry.firstMaterial.diffuse.contents = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.8];
    self.arrowBase = arrowBaseNode;
    
    [self.sceneView.pointOfView addChildNode:arrowBaseNode];
    
    SCNNode *arrowNode = [SCNNode nodeWithGeometry:[SCNBox boxWithWidth:0.01 height:0.01 length:0.01 chamferRadius:0]];
    arrowNode.name = @"arrow";
    arrowNode.position = SCNVector3Make(0, 0.01, -0.2);
    arrowNode.geometry.firstMaterial.diffuse.contents = [UIColor colorWithRed:0 green:1 blue:1 alpha:1];
    self.arrow = arrowNode;

    [self.sceneView.pointOfView addChildNode:arrowNode];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self addObject];
}

- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame {
    SCNVector3 arrowBasePos = self.arrowBase.position;
    
    double distanceToNearest = 1000;
    SCNVector3 nearestPos = SCNVector3Zero;
    NSArray *array = _sceneView.scene.rootNode.childNodes;
    for (SCNNode *child in _sceneView.scene.rootNode.childNodes) {
        if ([child.name isEqualToString:@"object"]) {
            SCNVector3 childPos = child.position;
            double distance = [self distanceBetween:_arrowBase.worldPosition and:childPos];

            child.geometry.firstMaterial.diffuse.contents = [UIColor colorWithRed:0 + [self sigmoidFunction:distance - 1] green:1 - [self sigmoidFunction:distance - 1] blue:0 alpha:1];
            if (distance < distanceToNearest) {
                distanceToNearest = distance;
                nearestPos = childPos;
//                child.geometry.firstMaterial.diffuse.contents = [UIColor blueColor];

            }
        }
    }
    
    NSLog(@"==============================");
    //    NSLog(@"%f %f %f",nearestPosInCamera.x,nearestPosInCamera.y,nearestPosInCamera.z);
    //    NSLog(@"%f %f %f",nearestPos.x,nearestPos.y,nearestPos.z);
    NSLog(@"%f %f %f",nearestPos.x, nearestPos.y, nearestPos.z);
    
    SCNVector3 nearestPosInCamera = [self positionOfWorldPointInCamera:nearestPos];
    
    SCNVector3 arrowDirection = SCNVector3Make(arrowBasePos.x - nearestPosInCamera.x, arrowBasePos.y - nearestPosInCamera.y, arrowBasePos.z - nearestPosInCamera.z);

    
    double directionMod = -1 * sqrt(pow(arrowDirection.x, 2) + pow(arrowDirection.y, 2) + pow(arrowDirection.z, 2));
    
    SCNVector3 directionNormal = SCNVector3Make(arrowDirection.x/directionMod, arrowDirection.y/directionMod, arrowDirection.z/directionMod);
    
    self.arrow.position = SCNVector3Make(directionNormal.x / 100, directionNormal.y / 100, directionNormal.z / 100 + arrowBasePos.z);
//    self.arrow.position = nearestPosInCamera;
}

- (SCNVector3)position:(matrix_float4x4)transform {
    return SCNVector3Make(transform.columns[3][0], transform.columns[3][1], transform.columns[3][2]);
}

- (double)distanceBetween:(SCNVector3)point1 and:(SCNVector3)point2 {
    return sqrtf(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2) + pow(point2.z - point1.z, 2));
}

- (double)angleBetween:(SCNVector3)vector1 and:(SCNVector3)vector2 {
    
    double scalar = vector1.x * vector2.x + vector1.y * vector2.y + vector1.z * vector2.z;
    
    double mod1 = sqrt(pow(vector1.x, 2) + pow(vector1.y, 2) + pow(vector1.z, 2));
    double mod2 = sqrt(pow(vector2.x, 2) + pow(vector2.y, 2) + pow(vector2.z, 2));
    
    return scalar/(mod1 * mod2);
}

- (double)sigmoidFunction:(double)x{
    return 1.0 / (1.0 + exp(-x));
}

- (SCNVector3)positionOfWorldPointInCamera:(SCNVector3)point {
    double x = self.sceneView.pointOfView.rotation.x;
    double y = self.sceneView.pointOfView.rotation.y;
    double z = self.sceneView.pointOfView.rotation.z;
    double w = self.sceneView.pointOfView.rotation.w;

//    SCNMatrix4 transform = self.sceneView.pointOfView.transform;
//
//    double xAngle = self.sceneView.pointOfView.rotation.x * self.sceneView.pointOfView.rotation.w;
//    double yAngle = self.sceneView.pointOfView.rotation.y * self.sceneView.pointOfView.rotation.w;
//    double zAngle = self.sceneView.pointOfView.rotation.z * self.sceneView.pointOfView.rotation.w;

    double cx = -self.sceneView.pointOfView.position.x;
    double cy = -self.sceneView.pointOfView.position.y;
    double cz = -self.sceneView.pointOfView.position.z;

    GLKMatrix3 cameraRotationMatrix = GLKMatrix3Make(cos(w) + pow(x, 2) * (1 - cos(w)),
                                                     x * y * (1 - cos(w)) - z * sin(w),
                                                     x * z * (1 - cos(w)) + y*sin(w),
                                              
                                                     y*x*(1-cos(w)) + z*sin(w),
                                                     cos(w) + pow(y, 2) * (1 - cos(w)),
                                                     y*z*(1-cos(w)) - x*sin(w),
                                              
                                                     z*x*(1 - cos(w)) - y*sin(w),
                                                     z*y*(1 - cos(w)) + x*sin(w),
                                                     cos(w) + pow(z, 2) * ( 1 - cos(w)));
    
//    x = point.x;
//    y = point.y * cos(xAngle) - point.z * sin(xAngle);
//    z = point.y * sin(xAngle) + point.z * cos(xAngle);
//    NSLog(@"%f %f %f", x, y, z);
//
//    point = SCNVector3Make(x, y, z);
//
//    x = point.x * cos(yAngle) + point.z * sin(yAngle);
//    y = point.y;
//    z = - point.x * sin(yAngle) + point.z * sin(yAngle);
//    NSLog(@"%f %f %f", x, y, z);
//
//    point = SCNVector3Make(x, y, z);
//
//    x = point.x * cos(zAngle) + point.y * sin(zAngle);
//    y = - point.x * sin(zAngle) + point.y * cos(zAngle);
//    z = point.z;
//    NSLog(@"%f %f %f", x, y, z);
//
    SCNVector3 point1 = SCNVector3Make(
        point.x * cameraRotationMatrix.m00 + point.y * cameraRotationMatrix.m10 + point.z * cameraRotationMatrix.m20 + cx,
        point.x * cameraRotationMatrix.m01 + point.y * cameraRotationMatrix.m11 + point.z * cameraRotationMatrix.m21 + cy,
        point.x * cameraRotationMatrix.m02 + point.y * cameraRotationMatrix.m12 + point.z * cameraRotationMatrix.m22 + cz);
//        NSLog(@"%f %f %f", point1.x, point1.y, point1.z);
//    GLKVector3 pointNew = GLKMatrix3MultiplyVector3(cameraRotationMatrix, GLKVector3Make(point.x, point.y, point.z));
//    NSLog(@"%f %f %f", pointNew.x, pointNew.y, pointNew.z);
    return point1;

//    return SCNVector3Make(cx + pointNew.x, cy + pointNew.y, cz + pointNew.z);
    
}

@end
