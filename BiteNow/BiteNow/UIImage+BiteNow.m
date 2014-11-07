//
//  UIImage+BiteNow.m
//  BiteNow
//
//  Created by Stephen Chan on 10/29/14.
//  Copyright (c) 2014 Delta Lab. All rights reserved.
//

#import "UIImage+BiteNow.h"

@implementation UIImage (BiteNow)

+(UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
