//
//  ViewController.m
//  quotes
//
//  Created by Daniel Simons on 5/16/15.
//  Copyright (c) 2015 Unofficial Calculators. All rights reserved.
//
#import "AVFoundation/AVFoundation.h"

#import "ViewController.h"
#import "mrinsult-Swift.h"
#import "NSString+HTML.h"
#import "ARSpeechActivity.h"
#import <iAd/iAd.h>
#import "Flurry.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet SpringLabel *quoteLabel;
@property (strong, nonatomic) IBOutlet SpringButton *playButton;
@property (strong, nonatomic) IBOutlet SpringButton *shareButton;
@property (strong, nonatomic) IBOutlet SpringImageView *chuckNorris;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;

@property (strong, nonatomic) NSDictionary *currentInsult;
@property (strong, nonatomic) NSMutableArray *allInsults;
@property (strong, nonatomic) NSNumber *index;

@property (strong, nonatomic) AVSpeechSynthesizer *synthesizer;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *previousButtonItem;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [Flurry startSession:@"3N3Y95QHHDPQW4YVNSBR"];

    self.index = 0;
    self.allInsults = [[NSMutableArray alloc] init];
    self.canDisplayBannerAds = YES;
    self.previousButtonItem.enabled = NO;
    // Create the request.
    [self getInsult];
}

- (void)getInsult {
    [Flurry logEvent:@"get insult"];
    if ([self.allInsults count] > self.index.integerValue) {
        self.currentInsult = [self.allInsults objectAtIndex:self.index.integerValue];
        [self updateUI];
    } else {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://quandyfactory.com/insult/json"]];
        
        // Specify that it will be a POST request
        request.HTTPMethod = @"GET";
        
        // This is how we set header fields
        [request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        //[request setValue:@"sc8oTQPaLFmshhUvDq4iPqkxYXZhp18WnbbjsnYM2AnVHozXIk" forHTTPHeaderField:@"X-Mashape-Key"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        // Create url connection and fire request
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
    self.currentInsult = [NSJSONSerialization JSONObjectWithData:self.responseData options:nil error:nil];
    
    [self.allInsults insertObject:self.currentInsult atIndex:self.index.integerValue];

    [self updateUI];
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
    NSAttributedString *attributedQuote = [[NSAttributedString alloc] initWithData:[[self.currentInsult objectForKey:@"insult"] dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:nil error:nil];

    [self.quoteLabel setText:attributedQuote.string];
    //[self.authorLabel setText:[NSString stringWithFormat:@"-%@",[quoteDict objectForKey:@"author"]]];
    
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
    self.playButton.duration = 1;
    self.playButton.delay = .5;
    [self.playButton animate];
    
    self.shareButton.animation = @"flip";
    self.shareButton.alpha = 1;
    self.shareButton.duration = 1;
    self.shareButton.delay = .3;
    [self.shareButton animate];
    
    
    self.chuckNorris.animation = @"flip";
    self.chuckNorris.duration = .7;
    self.chuckNorris.delay = .2;
    [self.chuckNorris animate];
    
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
    [Flurry logEvent:@"pressed play button"];

    self.playButton.animation = @"morph";
    self.playButton.duration = 2;
    [self.playButton animate];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:self.quoteLabel.text];
    //utterance.rate = AVSpeechUtteranceDefaultSpeechRate;
    utterance.rate = .08;
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-us"];
    
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    [self.synthesizer speakUtterance:utterance];
}

- (IBAction)didPressNext:(id)sender {
    self.previousButtonItem.enabled = YES;
    self.index = [NSNumber numberWithInteger:self.index.integerValue + 1];

    [self getInsult];
}


- (IBAction)didPressLast:(id)sender {
    self.index = [NSNumber numberWithInteger:self.index.integerValue - 1];

    if (self.index.integerValue == 0) {
        self.previousButtonItem.enabled = NO;
    }
    
    [self getInsult];
}

- (IBAction)didPressShare:(id)sender {
    if ([sender isKindOfClass:[SpringButton class]]) {
        ((SpringButton*)sender).animation = @"morph";
        [sender animate];
    }
    NSString *screenshotText = self.quoteLabel.text;
    UIImage *image = self.chuckNorris.image;
    
    ARSpeechActivity *speechActivity = [[ARSpeechActivity alloc] init];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[screenshotText, image] applicationActivities:@[speechActivity]];
    
    if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
        activityVC.popoverPresentationController.barButtonItem = self.shareBarButtonItem; 
    }
    
    activityVC.excludedActivityTypes = @[UIActivityTypePostToVimeo, UIActivityTypePostToWeibo];
    
    [self presentViewController:activityVC animated:YES completion:nil];
}



@end
