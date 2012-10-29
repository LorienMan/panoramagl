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

#import "PLPanoramaBaseProtected.h"
#import "PLSpherical4Panorama.h"

@interface PLSpherical4Panorama(Private)

-(void)setTexture:(PLTexture *)texture face:(PLSpherical4FaceOrientation)face;
    
@end

@implementation PLSpherical4Panorama

@synthesize divs, previewDivs;

#pragma mark -
#pragma mark init methods

+(id)panorama
{
    return [[[PLSpherical2Panorama alloc] init] autorelease];
}

-(void)initializeValues
{
    [super initializeValues];
	quadratic = gluNewQuadric();
	gluQuadricNormals(quadratic, GLU_SMOOTH);
	gluQuadricTexture(quadratic, YES);
	divs = kDefaultHemisphereDivs;
    previewDivs = kDefaultHemispherePreviewDivs;
}

#pragma mark -
#pragma mark property methods

-(PLSceneElementType)getType
{
	return PLSceneElementTypePanorama;
}

-(int)getPreviewSides
{
	return 1;
}

-(int)getSides
{
	return 4;
}

-(void)setImage:(PLImage *)image
{
    if(image && [image getWidth] == 2048*2 && [image getHeight] == 1024*2)
    {
        PLImage *frontImage = [[image clone] crop:CGRectMake(2*768.0f, 0.0f, 2*512.0f, 2*1024.0f)];
        PLImage *backImage = [PLImage joinImagesHorizontally:[[image clone] crop:CGRectMake(2*1792.0f, 0.0f, 2*256.0f, 2*1024.0f)] rightImage:[[image clone] crop:CGRectMake(0.0f, 0.0f, 2*256.0f, 2*1024.0f)]];
        PLImage *rightImage = [[image clone] crop:CGRectMake(2*1024.0f, 0.0f, 2*1024.0f, 2*1024.0f)];
        [image crop:CGRectMake(0.0, 0.0f, 2*1024.0f, 2*1024.0f)];
        [self setTexture:[PLTexture textureWithImage:frontImage] face:PLSpherical4FaceOrientationFront];
        [self setTexture:[PLTexture textureWithImage:image] face:PLSpherical4FaceOrientationLeft];
        [self setTexture:[PLTexture textureWithImage:rightImage] face:PLSpherical4FaceOrientationRight];
        [self setTexture:[PLTexture textureWithImage:backImage] face:PLSpherical4FaceOrientationBack];
    }
}

-(void)setTexture:(PLTexture *)texture face:(PLSpherical4FaceOrientation)face
{
    if(texture)
    {
        @synchronized(self)
        {
			PLTexture **textures = [self getTextures];
			PLTexture *currentTexture = textures[face];
			if(currentTexture)
				[currentTexture release];
			textures[face] = [texture retain];
		}
	}
}

#pragma mark -
#pragma mark render methods

-(void)internalRender
{
    glRotatef(180.0f, 0.0f, 1.0f, 0.0f);
    
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_FRONT);
    
    PLTexture *previewTexture = [self getPreviewTextures][0];
    PLTexture **textures = [self getTextures];
    PLTexture *frontTexture = textures[PLSpherical4FaceOrientationFront];
    PLTexture *backTexture = textures[PLSpherical4FaceOrientationBack];
    PLTexture *leftTexture = textures[PLSpherical4FaceOrientationLeft];
    PLTexture *rightTexture = textures[PLSpherical4FaceOrientationRight];
    
    BOOL previewTextureIsValid = (previewTexture && previewTexture.textureID);
    BOOL frontTextureIsValud = (frontTexture && frontTexture.textureID);
    BOOL backTextureIsValid = (backTexture && backTexture.textureID);
    BOOL leftTextureIsValid = (leftTexture && leftTexture.textureID);
    BOOL rightTextureIsValid = (rightTexture && rightTexture.textureID);
    
    if(previewTextureIsValid)
    {
        if(frontTextureIsValud && backTextureIsValid && leftTextureIsValid && rightTextureIsValid)
            [self removePreviewTextureAtIndex:0];
        else
        {
            glBindTexture(GL_TEXTURE_2D, previewTexture.textureID);
            gluSphere(quadratic, kRatio + 0.05f, previewDivs, previewDivs);
        }
    }
    if(frontTextureIsValud)
    {
        glBindTexture(GL_TEXTURE_2D, frontTexture.textureID);
        glu3DArc(quadratic, M_PI_2, -M_PI_4, NO, kRatio, divs, divs);
    }
    if(backTextureIsValid)
    {
        glBindTexture(GL_TEXTURE_2D, backTexture.textureID);
        glu3DArc(quadratic, M_PI_2, -M_PI_4, YES, kRatio, divs, divs);
    }
    if(leftTextureIsValid)
    {
        glBindTexture(GL_TEXTURE_2D, leftTexture.textureID);
        gluHemisphere(quadratic, NO, kRatio, divs, divs);
    }
    if(rightTextureIsValid)
    {
        glBindTexture(GL_TEXTURE_2D, rightTexture.textureID);
        gluHemisphere(quadratic, YES, kRatio, divs, divs);
    }
    
	glDisable(GL_TEXTURE_2D);
    
    glRotatef(-180.0f, 0.0f, 1.0f, 0.0f);
    glRotatef(90.0f, 1.0f, 0.0f, 0.0f);
    
    [super internalRender];
}

#pragma mark -
#pragma mark dealloc methods

-(void)dealloc
{
	if(quadratic)
	{
		gluDeleteQuadric(quadratic);
		quadratic = nil;
	}
	[super dealloc];
}

@end
