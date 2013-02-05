/*
 * PanoramaGL library
 * Version 0.1
 * Copyright (c) 2010 Javier Baez <javbaezga@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * This functions are a port from C++ to Objective-C of 
 * "Demonstration of a line mesh intersection test (Sample1-Mesh_Line_Intersection.zip)" 
 * example by Jonathan Kreuzer http://www.3dkingdoms.com/weekly. 
 * See checkLineBoxWithRay.h and checkLineBoxWithRay.cpp.
 */

#import "PLIntersection.h"

@interface PLIntersection (Private)

+ (BOOL)getIntersectionWithDistance1:(float)distance1 distance2:(float)distance2 ray:(PLVector3 **)ray hitPoint:(PLVector3 **)hitPoint;
+ (BOOL)inBoxWithHitPoint:(PLVector3 *)hitPoint startBound:(PLVector3 *)startBound endBound:(PLVector3 *)endBound axis:(int)axis;
+ (BOOL)evalSideIntersectionWithDistance1:(float)distance1 distance2:(float)distance2 ray:(PLVector3 **)ray hitPoint:(PLVector3 **)hitPoint startBound:(PLVector3 *)startBound endBound:(PLVector3 *)endBound axis:(int)axis;

@end

@implementation PLIntersection

#pragma mark -
#pragma mark init methods

- (id)init
{
    return nil;
}

#pragma mark -
#pragma mark internal check methods

+ (BOOL)getIntersectionWithDistance1:(float)distance1 distance2:(float)distance2 ray:(PLVector3 **)ray hitPoint:(PLVector3 **)hitPoint
{
    if (distance1 * distance2 >= 0.0f || distance1 == distance2)
        return NO;
    PLVector3 *sub = [ray[1] sub:ray[0]];
    PLVector3 *mult = [sub multf:-distance1 / (distance2 - distance1)];
    *hitPoint = [mult add:ray[0]];
    return YES;
}

+ (BOOL)inBoxWithHitPoint:(PLVector3 *)hitPoint startBound:(PLVector3 *)startBound endBound:(PLVector3 *)endBound axis:(int)axis
{
    if (axis == 1 && hitPoint.z > startBound.z && hitPoint.z < endBound.z && hitPoint.y > startBound.y && hitPoint.y < endBound.y) return YES;
    if (axis == 2 && hitPoint.z > startBound.z && hitPoint.z < endBound.z && hitPoint.x > startBound.x && hitPoint.x < endBound.x) return YES;
    if (axis == 3 && hitPoint.x > startBound.x && hitPoint.x < endBound.x && hitPoint.y > startBound.y && hitPoint.y < endBound.y) return YES;
    return NO;
}

+ (BOOL)evalSideIntersectionWithDistance1:(float)distance1 distance2:(float)distance2 ray:(PLVector3 **)ray hitPoint:(PLVector3 **)hitPoint startBound:(PLVector3 *)startBound endBound:(PLVector3 *)endBound axis:(int)axis
{
    if ([PLIntersection getIntersectionWithDistance1:distance1 distance2:distance2 ray:ray hitPoint:hitPoint]) {
        if (![PLIntersection inBoxWithHitPoint:*hitPoint startBound:startBound endBound:endBound axis:axis])
            return NO;
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark check methods

+ (BOOL)checkLineBoxWithRay:(PLVector3 **)ray startBound:(PLVector3 *)startBound endBound:(PLVector3 *)endBound hitPoint:(PLVector3 **)hitPoint
{
    *hitPoint = nil;

    //Check for a quick exit if ray is completely to one side of the box
    if (
            (ray[1].x < startBound.x && ray[0].x < startBound.x) ||
                    (ray[1].x > endBound.x && ray[0].x > endBound.x) ||
                    (ray[1].y < startBound.y && ray[0].y < startBound.y) ||
                    (ray[1].y > endBound.y && ray[0].y > endBound.y) ||
                    (ray[1].z < startBound.z && ray[0].z < startBound.z) ||
                    (ray[1].z > endBound.z && ray[0].z > endBound.z)
            )
        return NO;

    //Check if ray originates in the box
    if (ray[0].x > startBound.x && ray[0].x < endBound.x && ray[0].y > startBound.y && ray[0].y < endBound.y && ray[0].z > startBound.z && ray[0].z < endBound.z) {
        *hitPoint = [ray[0] clone];
        return YES;
    }

    //Check for a ray intersection with each side of the box
    if (
            ([PLIntersection evalSideIntersectionWithDistance1:ray[0].x - startBound.x distance2:ray[1].x - startBound.x ray:ray hitPoint:hitPoint startBound:startBound endBound:endBound axis:1]) ||
                    ([PLIntersection evalSideIntersectionWithDistance1:ray[0].y - startBound.y distance2:ray[1].y - startBound.y ray:ray hitPoint:hitPoint startBound:startBound endBound:endBound axis:2]) ||
                    ([PLIntersection evalSideIntersectionWithDistance1:ray[0].z - startBound.z distance2:ray[1].z - startBound.z ray:ray hitPoint:hitPoint startBound:startBound endBound:endBound axis:3]) ||
                    ([PLIntersection evalSideIntersectionWithDistance1:ray[0].x - endBound.x distance2:ray[1].x - endBound.x ray:ray hitPoint:hitPoint startBound:startBound endBound:endBound axis:1]) ||
                    ([PLIntersection evalSideIntersectionWithDistance1:ray[0].y - endBound.y distance2:ray[1].y - endBound.y ray:ray hitPoint:hitPoint startBound:startBound endBound:endBound axis:2]) ||
                    ([PLIntersection evalSideIntersectionWithDistance1:ray[0].z - endBound.z distance2:ray[1].z - endBound.z ray:ray hitPoint:hitPoint startBound:startBound endBound:endBound axis:3])
            )
        return YES;

    return NO;
}

+ (BOOL)checkCollisionWithRay:(PLVector3 **)ray point1:(PLVector3 *)v0 point2:(PLVector3 *)v1 point3:(PLVector3 *)v2 hitPoint:(PLVector3 **)hitPoint
{
    PLVector3 *point = [self intersectionWithRay:ray point1:v0 point2:v1 point3:v2];
    if (point) {
        if ([self point:point inTrianglePoint1:v0 point2:v1 point3:v2]) {
            *hitPoint = point;
            return YES;
        }
    }

    return NO;
}

#define crossProduct(a,b,c) \
    a.x = (b.y * c.z) - (c.y * b.z); \
    a.y = (b.z * c.x) - (c.z * b.x); \
    a.z = (b.x * c.y) - (c.x * b.y);

#define dotProduct(v,q) ((v.x * q.x) + (v.y * q.y) + (v.z * q.z))
#define createVector(a,b) [PLVector3 vector3WithX:b.x - a.x y:b.y - a.y z:b.z - a.z]
#define vectorLength(a) sqrt(a.x*a.x + a.y*a.y + a.z*a.z)
#define normalizeVector(a) {float d = vectorLength(a); a.x/=d; a.y/=d; a.z/=d;}

+ (BOOL)point:(PLVector3 *)p4 inTrianglePoint1:(PLVector3 *)p1 point2:(PLVector3 *)p2 point3:(PLVector3 *)p3
{
    PLVector3 *p12 = createVector(p1,p2);
    PLVector3 *p13 = createVector(p1,p3);
    PLVector3 *p14 = createVector(p1,p4);

    float dot00 = dotProduct(p13, p13);
    float dot01 = dotProduct(p13, p12);
    float dot02 = dotProduct(p13, p14);
    float dot11 = dotProduct(p12, p12);
    float dot12 = dotProduct(p12, p14);

    float inverseDenominator = (1 / (dot00*dot11 - dot01*dot01));

    float u = (dot11 * dot02 - dot01*dot12) * inverseDenominator;
    float v = (dot00 * dot12 - dot01*dot02) * inverseDenominator;

    return u >= 0 && v >= 0 && u + v < 1;
}

+ (PLVector3 *)intersectionWithRay:(PLVector3 **)ray point1:(PLVector3 *)a point2:(PLVector3 *)b point3:(PLVector3 *)c
{
    PLVector3 *x = ray[0];
    PLVector3 *y = ray[1];
    PLVector3 *w = createVector(x, y);
    PLVector3 *toBegin = createVector(x, a);
    
    CGFloat cos = dotProduct(w, toBegin) / vectorLength(w) / vectorLength(toBegin);
    
    if (cos < 0 )
        return nil;
    
    
    PLVector3 *n = [PLVector3 vector3];
    PLVector3 *ab = createVector(a, b);
    PLVector3 *ac = createVector(a, c);
    crossProduct(n, ab, ac);
    normalizeVector(n);

    PLVector3 *v = createVector(x, a);
    float d = dotProduct(n, v);
    float e = dotProduct(n, w);

    if (fabsf(e) > 0.001) {
        return [PLVector3 vector3WithX:x.x + w.x*d/e y:x.y + w.y*d/e z:x.z + w.z*d/e];
    }

    return nil;
}

+ (BOOL)checkLineBoxWithRay:(PLVector3 **)ray point1:(PLVector3 *)point1 point2:(PLVector3 *)point2 point3:(PLVector3 *)point3 point4:(PLVector3 *)point4 hitPoint:(PLVector3 **)hitPoint
{

    if ( [self checkCollisionWithRay:ray point1:point1 point2:point2 point3:point3 hitPoint:hitPoint] ||
            [self checkCollisionWithRay:ray point1:point1 point2:point2 point3:point4 hitPoint:hitPoint] ||
            [self checkCollisionWithRay:ray point1:point1 point2:point3 point3:point4 hitPoint:hitPoint] ||
            [self checkCollisionWithRay:ray point1:point2 point2:point3 point3:point4 hitPoint:hitPoint]
            )
        return YES;
    return NO;
}

+ (BOOL)checkLineTriangleWithRay:(PLVector3 **)ray firstVertex:(PLVector3 *)firstVertex secondVertex:(PLVector3 *)secondVertex thirdVertex:(PLVector3 *)thirdVertex hitPoint:(PLVector3 **)hitPoint
{
    *hitPoint = nil;

    //Calculate triangle normal
    PLVector3 *normal = [[secondVertex sub:firstVertex] crossProduct:[thirdVertex sub:firstVertex]];
    [normal normalize];

    //Find distance from ray to the plane defined by the triangle
    float distance1 = [[ray[0] sub:firstVertex] dot:normal];
    float distance2 = [[ray[1] sub:firstVertex] dot:normal];

    if ((distance1 * distance2 >= 0.0f) ||    //Ray doesn't cross the triangle.
            (distance1 == distance2))            //Ray and plane are parallel.
        return NO;

    //Find point on the ray that intersects with the plane
    PLVector3 *intersect = [ray[0] add:[[ray[1] sub:ray[0]] multf:-distance1 / (distance2 - distance1)]];

    //Find if the intersection point lies inside the triangle by testing it against all edges
    if ([[normal crossProduct:[secondVertex sub:firstVertex]] dot:[intersect sub:firstVertex]] < 0.0f)
        return NO;

    if ([[normal crossProduct:[thirdVertex sub:secondVertex]] dot:[intersect sub:secondVertex]] < 0.0f)
        return NO;

    if ([[normal crossProduct:[firstVertex sub:thirdVertex]] dot:[intersect sub:firstVertex]] < 0.0f)
        return NO;

    *hitPoint = intersect;
    return YES;
}

@end