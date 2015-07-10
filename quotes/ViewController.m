//
//  ViewController.m
//  quotes
//
//  Created by Daniel Simons on 5/16/15.
//  Copyright (c) 2015 Unofficial Calculators. All rights reserved.
//
#import "AVFoundation/AVFoundation.h"

#import "ViewController.h"
#import "shakespeare-Swift.h"
#import "NSString+HTML.h"
#import "ARSpeechActivity.h"
#import <iAd/iAd.h>
#import <Parse/Parse.h>

@interface ViewController ()
@property (strong, nonatomic) IBOutlet SpringLabel *quoteLabel;
@property (weak, nonatomic) IBOutlet SpringLabel *authorLabel;
@property (weak, nonatomic) IBOutlet SpringImageView *authorPhoto;
@property (strong, nonatomic) IBOutlet SpringButton *playButton;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;

@property (strong, nonatomic) NSArray *allJokes;
@property (strong, nonatomic) NSNumber *index;

@property (strong, nonatomic) AVSpeechSynthesizer *synthesizer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.index = [NSNumber numberWithInteger:0];
    self.canDisplayBannerAds = YES;
    // Create the request.
    NSString *categoryString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"quoteCategory"];
    [[[PFQuery queryWithClassName:@"Quote"] whereKey:@"category" equalTo:categoryString] findObjectsInBackgroundWithBlock:^(NSArray *quotes, NSError *error) {
        for (PFObject *quote in quotes) {
            [quote pin];
        }
        self.allJokes = quotes;
        
        [self updateUI];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.synthesizer) {
        [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.synthesizer) {
        [self.synthesizer continueSpeaking];
    }
}


- (void)updateUI {
    NSDictionary *firstJoke = [self.allJokes objectAtIndex:self.index.integerValue];

    NSAttributedString *attributedQuote = [[NSAttributedString alloc] initWithData:[[firstJoke objectForKey:@"text"] dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:nil error:nil];
    
    [self.quoteLabel setText:attributedQuote.string];
    [self.authorLabel setText:[NSString stringWithFormat:@"%@",[firstJoke objectForKey:@"author"]]];
    
    self.quoteLabel.animation = @"slideDown";
    self.quoteLabel.alpha = 1;
    self.quoteLabel.duration = .6;
    self.quoteLabel.velocity = 2;
    [self.quoteLabel animate];
    
//    self.authorLabel.animation = @"zoomIn";
//    self.authorLabel.alpha = 1;
//    [self.authorLabel animate];

    self.playButton.animation = @"flip";
    self.playButton.alpha = 1;
    self.playButton.duration = .4;
    self.playButton.delay = .4;
    [self.playButton animate];
    
    self.authorLabel.animation = @"slideUp";
    self.authorLabel.alpha = 1;
    self.authorLabel.duration = .6;
    self.authorLabel.velocity = 3;
    [self.authorLabel animate];
    
    self.authorPhoto.animation = @"slideUp";
    self.authorPhoto.alpha = 1;
    self.authorPhoto.duration = .6;
    self.authorPhoto.velocity = 3;
    [self.authorPhoto animate];
    
    [self.activityView stopAnimating];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    if (error) {
        [self.quoteLabel setText:@"It appears you are not connected to the internet. Refresh"];
    }
}
- (IBAction)didPressPlay:(id)sender {
    
    self.playButton.animation = @"morph";
    self.playButton.duration = 1;
    self.playButton.delay = 0;
    [self.playButton animate];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:self.quoteLabel.text];
    //utterance.rate = AVSpeechUtteranceDefaultSpeechRate;
    utterance.rate = .08;
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-us"];
    
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    [self.synthesizer speakUtterance:utterance];
}

- (IBAction)didPressNext:(id)sender {
    if (self.index.integerValue == self.allJokes.count - 1) {
        self.index = 0;
    } else {
        self.index = [NSNumber numberWithInteger:self.index.integerValue + 1 ];
    }
    [self updateUI];
}


- (IBAction)didPressLast:(id)sender {
    if (self.index.integerValue == 0) {
        self.index = [NSNumber numberWithInteger:self.allJokes.count - 1];
    } else {
        self.index = [NSNumber numberWithInteger:self.index.integerValue - 1 ];
    }
    [self updateUI];
}

- (IBAction)didPressShare:(id)sender {
    if ([sender isKindOfClass:[SpringButton class]]) {
        ((SpringButton*)sender).animation = @"morph";
        [sender animate];
    }
    NSString *screenshotText = self.quoteLabel.text;
    NSString *authorText = self.authorLabel.text;
    
    ARSpeechActivity *speechActivity = [[ARSpeechActivity alloc] init];
    
    NSString *appstoreURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"appstoreURL"];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[screenshotText,authorText, [NSString stringWithFormat:@"... For more quotes download %@", appstoreURL]] applicationActivities:@[speechActivity]];
    
    if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
        activityVC.popoverPresentationController.barButtonItem = self.shareBarButtonItem;
    }
    activityVC.excludedActivityTypes = @[UIActivityTypePostToVimeo, UIActivityTypePostToWeibo];
    
    [self presentViewController:activityVC animated:YES completion:nil];
}



@end
