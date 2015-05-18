//
//  ViewController.h
//  quotes
//
//  Created by Daniel Simons on 5/16/15.
//  Copyright (c) 2015 Unofficial Calculators. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<NSURLConnectionDelegate>

@property (strong, nonatomic) NSMutableData *responseData;

@end

