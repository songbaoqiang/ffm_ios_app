//
//  FlyingMediaVC.m
//  FlyingEnglish
//
//  Created by vincent sung on 11/26/15.
//  Copyright © 2015 BirdEngish. All rights reserved.
//

#import "FlyingMediaVC.h"

#import "shareDefine.h"
#import "FlyingPubLessonData.h"
#import "FlyingLessonData.h"
#import "FlyingLessonDAO.h"

#import "UICKeyChainStore.h"

#import "iFlyingAppDelegate.h"

#import "FlyingSoundPlayer.h"

#import "NSString+FlyingExtention.h"

#import "FlyingM3U8Downloader.h"
#import <QuartzCore/QuartzCore.h>

#import "UIImage+localFile.h"
#import "FlyingSubTitle.h"
#import "UIView+Autosizing.h"
#import <UIImageView+AFNetworking.h>
#import "UIImage+localFile.h"

#import "FlyingLoadingView.h"
#import "FlyingLessonParser.h"
#import "ReaderViewController.h"

#import "FlyingStatisticDAO.h"
#import "FlyingContentListVC.h"

#import <ZXMultiFormatWriter.h>
#import <ZXImage.h>
#import "FlyingSearchViewController.h"

#import "FlyingWordDetailVC.h"
#import "FlyingSeparateView.h"

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSKeyedArchiver.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CMTime.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVMediaFormat.h>
#import <QuartzCore/CALayer.h>

#import "FlyingAILearningView.h"
#import "FlyingGestureControlView.h"
#import "FlyingSubtitleTextView.h"
#import "FlyingWordLinguisticData.h"
#import "FlyingSubRipItem.h"
#import "FlyingSubTitle.h"
#import "ACMagnifyingGlass.h"
#import "FlyingLessonData.h"
#import "FlyingLessonDAO.h"
#import "FlyingTaskWordDAO.h"
#import "UICKeyChainStore.h"
#import "FlyingTagTransform.h"
#import "NSString+FlyingExtention.h"
#import "FlyingSoundPlayer.h"
#import "iFlyingAppDelegate.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FlyingStatisticDAO.h"
#import "UIView+Autosizing.h"
#import "UIImage+localFile.h"
#import "FlyingM3U8Downloader.h"
#import "FlyingPlayerView.h"
#import "NSString+FlyingExtention.h"
#import "FlyingItemView.h"
#import "FlyingItemData.h"
#import "MotionOrientation.h"
#import <MediaPlayer/MPVolumeView.h>
#import "FlyingTaskWordDAO.h"
#import <CRToastManager.h>
#import <AFNetworking.h>
#import "AFHttpTool.h"
#import "iFlyingAppDelegate.h"
#import "FlyingItemParser.h"
#import "FlyingItemDao.h"
#import "SSZipArchive.h"
#import "FlyingContentVC.h"
#import "FlyingDownloadManager.h"
#import "FlyingConversationVC.h"
#import "FlyingDataManager.h"

static void *PlayerItemStatusObserverContext = &PlayerItemStatusObserverContext;
static void *SubtitlStatusObserverContext    = &SubtitlStatusObserverContext;
static void *RateObservationContext          = &RateObservationContext;
static void *TrackObservationContext         = &TrackObservationContext;

@interface FlyingMediaVC ()<FlyingItemViewDelegate>
{
    FlyingLessonDAO     *_lessonDAO;
    FlyingLessonData    *_lessonData;
    
    NSString            * _currentPassport;
    
    //后台处理
    dispatch_queue_t   _background_queue;
    
    CGFloat            _margin;
    float              _width;
    
    //视频专用
    FlyingSubTitle           *_subtitleFile;
    NSMutableDictionary      *_annotationWordViews;
    
    ACMagnifyingGlass        *_mag;
    FlyingWordLinguisticData *_theOnlyTagWord;
    
    BOOL                     _enableAutoUpdateSub;
    BOOL                     _enableMagicGame;
    
    //Magic Game
    NSInteger                _magicGameIndex;
    
    UIImage                  *_lastScreen;
    
    FlyingTagTransform       *_tagTransform;
    FlyingSoundPlayer        *_speechPlayer;
    
    NSInteger                 _balanceCoin;
    NSInteger                 _touchWordCount;
    
    NSString                 * _movieURLStr;
    BE_Vedio_Type              _contentType;
    NSTimeInterval             _totalDuration;
    
    double                     _startTime;
    double                     _endTime;
    
    //播放控制
    int32_t                   _timeScale;
    BOOL                      _firstPlaying;    //帮助判断是否需要自己播放
    NSTimeInterval            _error;           //字幕播放误差
    BOOL                      _isClosedFlag;    //关闭标志，控制是或否背后播放
    
    //M3U8相关
    UIWebView                * _webView;
    BOOL                       _needShareM3U8URL;
    BOOL                       _parseContentURLOK;
    BOOL                       _needParserContentURL;
    
    float                      _ratioHeightToW;
    CGSize                     _deviceSize;
    
    UILabel                   *_lessonSumarySep;
    UILabel                   *_relatedContentSep;
    UILabel                   *_lessonTagSep;
    UILabel                   *_keyPointSep;
    UILabel                   *_keyWordSep;
    UILabel                   *_qrcodeSep;
}

@property (strong, nonatomic) AVPlayer          *player;
@property (strong, nonatomic) AVPlayerItem      *playerItem;
@property (strong, nonatomic) IBOutlet FlyingPlayerView *playerView;
@property (strong, nonatomic) id                 playerObserver;

@property (strong, nonatomic) IBOutlet FlyingAILearningView     *aiLearningView;
@property (strong, nonatomic) IBOutlet FlyingGestureControlView *gestureControlView;

@property (strong, nonatomic) IBOutlet UIView                  *buttonsView;
@property (strong, nonatomic) IBOutlet UISlider                *slider;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@property (strong, nonatomic) IBOutlet UIImageView              *magicImageView;
@property (strong, nonatomic) IBOutlet UIImageView              *fullImageView;

@property (strong, nonatomic) IBOutlet FlyingSubtitleTextView   *subtitleTextView;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView  *indicatorView;

@property (assign, nonatomic) NSTimeInterval            timestamp;

@property (assign, nonatomic) BOOL       toFullScreen;

@property (strong, nonatomic) NSMutableDictionary   *subtitleAIDic;
@property (assign, nonatomic) NSInteger   currentAIIndex;

@end

@implementation FlyingMediaVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.thePubLesson) {

        [self initData];
        [self showLoadingIndicator];
        [self playVedio];
    }
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(self.player)
    {
        [self playAndDoAI];
    }
    
    //监控
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(godReset)
                                                 name:KGodIsComing
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KGodIsComing    object:nil];

    if(self.player)
    {
        [self pauseAndDoAI];
    }
    
    [super viewWillDisappear:animated];
}

-(void) viewDidDisappear:(BOOL)animated
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:_lessonData.localURLOfSub]) {
        [[NSFileManager defaultManager] removeItemAtPath:_lessonData.localURLOfSub error:nil];
    }
    
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}


-(void)godReset
{
    if (self.player) {
        [self dismiss];
    }
}

-(void)play
{
    if (self.player) {
        
        [self.player play];
    }
}

-(void)pause;
{
    if (self.player) {
        
        [self.player pause];
    }
}

//////////////////////////////////////////////////////////////
#pragma  准备有关数据
//////////////////////////////////////////////////////////////
-(void) initData
{
    NSString *openID = [FlyingDataManager getOpenUDID];
    
    _currentPassport = openID;
    
    if(!_background_queue){
        
        _background_queue = dispatch_queue_create("com.birdengcopy.background.processing", NULL);
    }
    
    if (!_lessonDAO) {
        
        _lessonDAO = [[FlyingLessonDAO alloc] init];
    }
    
    self.toFullScreen=YES;
    
    _lessonData    = [_lessonDAO selectWithLessonID:self.thePubLesson.lessonID];
}

//////////////////////////////////////////////////////////////
#pragma mark - loading prosessing
//////////////////////////////////////////////////////////////
-(void) showLoadingIndicator
{
    [self.indicatorView setHidden:NO];
    [self.indicatorView startAnimating];
}

-(void) hideLoadingIndicator
{
    if (self.indicatorView)
    {
        [self.indicatorView stopAnimating];
    }
}

//////////////////////////////////////////////////////////////
#pragma Play vedio and audio
//////////////////////////////////////////////////////////////
- (void)playVedio
{
    //基本辅助信息和工具准备
    _tagTransform=[[FlyingTagTransform alloc] init];
    
    _speechPlayer = [[FlyingSoundPlayer alloc] init];
    _lastScreen=nil;
    
    //字幕相关
    _enableAutoUpdateSub=NO;
    
    //收费相关
    FlyingStatisticDAO *statisticDAO = [[FlyingStatisticDAO alloc] init];
    [statisticDAO initDataForUserID:_currentPassport];
    
    _touchWordCount = [statisticDAO touchCountWithUserID:_currentPassport];
    _balanceCoin  = [statisticDAO finalMoneyWithUserID:_currentPassport];
    
    //播放器准备
    [self prepareMovie];
}

-(void) preparePlayAndControlView
{
    self.aiLearningView.userInteractionEnabled=YES;
    self.aiLearningView.multipleTouchEnabled=YES;
    self.aiLearningView.backgroundColor=[UIColor clearColor];
    self.aiLearningView.delegate=self;
    
    self.gestureControlView.userInteractionEnabled=YES;
    self.gestureControlView.multipleTouchEnabled=YES;
    self.gestureControlView.backgroundColor=[UIColor clearColor];
    
    [self addPlayBaseControlGestureRecognizer];
    
    self.buttonsView.userInteractionEnabled=YES;
    self.buttonsView.multipleTouchEnabled=YES;
    self.buttonsView.alpha=0;

    [self.slider setTintColor:[UIColor redColor]];
    
    UIImage *thumbImage = [UIImage imageNamed:@"thumb"];
    if (INTERFACE_IS_PAD) {
        
        [self.slider setThumbImage:[self OriginImage:thumbImage scaleToSize:CGSizeMake(32,32)] forState:UIControlStateHighlighted];
        [self.slider setThumbImage:[self OriginImage:thumbImage scaleToSize:CGSizeMake(32,32)] forState:UIControlStateNormal];
    }
    else
    {
        [self.slider setThumbImage:[self OriginImage:thumbImage scaleToSize:CGSizeMake(24,24)] forState:UIControlStateHighlighted];
        [self.slider setThumbImage:[self OriginImage:thumbImage scaleToSize:CGSizeMake(24,24)] forState:UIControlStateNormal];
    }

    
    [self.slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventTouchDragInside];
    [self.slider addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [self.slider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    [self.slider addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
    
    [self.slider  setValue:0];
    self.slider.userInteractionEnabled=NO;
    self.slider.multipleTouchEnabled = NO;
    
    self.timeLabel.textColor =[UIColor whiteColor];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.numberOfLines=0;
    if (INTERFACE_IS_PAD) {
        self.timeLabel.font    = [UIFont systemFontOfSize:15.0];
    }
    else{
        self.timeLabel.font     = [UIFont systemFontOfSize:7.0];
    }
    
    self.magicImageView.image = [UIImage imageNamed:@"off"];
    self.magicImageView.userInteractionEnabled=YES;
    
    self.magicImageView.contentMode=UIViewContentModeScaleAspectFit;
    // 单击的 Recognizer
    UITapGestureRecognizer *singleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doMagic)];
    singleRecognizer.numberOfTapsRequired = 1; // 单击
    [self.magicImageView addGestureRecognizer:singleRecognizer];
    self.magicImageView.hidden=YES;
    self.magicImageView.alpha=0.6;
    
    self.fullImageView.image = [UIImage imageNamed:@"full"];
    self.fullImageView.userInteractionEnabled=YES;
    
    self.fullImageView.contentMode=UIViewContentModeScaleAspectFit;
    // 单击的 Recognizer
    UITapGestureRecognizer *fullImageViewSingleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doSwitchFullScreen)];
    fullImageViewSingleRecognizer.numberOfTapsRequired = 1; // 单击
    [self.fullImageView addGestureRecognizer:fullImageViewSingleRecognizer];
    self.fullImageView.hidden=NO;
    
    //字幕基本设置|默认黑底风格字幕
    self.subtitleTextView.text=@"";
    self.subtitleTextView.hidden=YES;
    self.subtitleTextView.font = [UIFont systemFontOfSize:KLargeFontSize];
    
    self.aiLearningView.subtitleTextView = self.subtitleTextView;

    //设置智能字幕和控制
    [self prepareControlAndAI];
    
    //设置加载
    self.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    self.indicatorView.backgroundColor = [UIColor clearColor];
    self.indicatorView.hidesWhenStopped=YES;
    [self.indicatorView startAnimating];
}

#pragma mark - prepare for playing

-(void) prepareMovie
{
    _error=0;
    _firstPlaying=YES;
    _movieURLStr=nil;
    _needParserContentURL=NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:_lessonData.localURLOfContent]){
        
        //本地
        if([NSString checkM3U8URL:_lessonData.localURLOfContent]){
            
            NSString* contentFileName     = [self.thePubLesson.lessonID stringByAppendingPathExtension:kLessonVedioLivingType];
            _movieURLStr=[NSString stringWithFormat:@"http://127.0.0.1:12345/%@/%@",self.thePubLesson.lessonID,contentFileName];
            
            _contentType=BELocalM3U8Vedio;
            
            iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate startLocalHttpserver];
        }
        else{
            
            _movieURLStr =_lessonData.localURLOfContent;
            
            if([NSString checkMp4URL:_lessonData.localURLOfContent]){
                
                _contentType=BELocalMp4Vedio;
            }
            else{
                
                if([NSString checkMp3URL:_lessonData.localURLOfContent]){
                    
                    _contentType=BELocalMp3Audio;
                }
                else{
                    
                    _contentType=BEWebSourceURL;
                }
            }
        }
    }
    else{
        
        //网络
        if([NSString checkMp4URL:_lessonData.localURLOfContent]){
            
            _movieURLStr =_lessonData.BECONTENTURL;
            _contentType=BEWebMp4Vedio;
        }
        else{
            
            if([NSString checkMp3URL:_lessonData.localURLOfContent]){
                
                _movieURLStr =_lessonData.BECONTENTURL;
                _contentType=BEWebMp3Audio;
            }
            else{
                
                if([NSString checkM3U8URL:_lessonData.localURLOfContent]){
                    
                    _movieURLStr =_lessonData.BECONTENTURL;
                    _contentType=BEWebM3U8Vedio;
                }
                else{
                    
                    _movieURLStr=nil;
                    _contentType=BEWebSourceURL;
                }
            }
        }
    }
    
    if(_contentType==BEWebMp3Audio || _contentType==BELocalMp3Audio){
        
        //去除播放内容视图
        [self.playerView removeFromSuperview];
    }
    
    if (_movieURLStr) {
        
        [self prepareAVPlayer];
    }
    else{
        
        _needParserContentURL=YES;
        [self getContentUrlFronWeb];
    }
}

-(void)  prepareAVPlayer
{
    //播放起始时间
    _initialPlaybackTime = 0;
    
    if(self.timestamp){
        
        self.initialPlaybackTime=self.timestamp;
    }
    
    self.timestamp=_initialPlaybackTime;
    
    NSURL *movieURL;
    
    switch (_contentType) {
        case BELocalMp4Vedio:
        case BELocalMp3Audio:
            movieURL = [NSURL fileURLWithPath:_movieURLStr];
            break;
        case BEWebMp4Vedio:
        case BEWebMp3Audio:
        case BEWebM3U8Vedio:
        case BELocalM3U8Vedio:
            movieURL = [NSURL URLWithString:_movieURLStr];
            break;
            
        default:
            movieURL=nil;
    }
    
    /*
     Create an asset for inspection of a resource referenced by a given URL.
     Load the values for the asset keys "tracks", "playable".
     */
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:movieURL options:NULL];
    
    NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
     ^{
         dispatch_async( dispatch_get_main_queue(),
                        ^{
                            /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                            [self prepareToPlayAsset:asset withKeys:requestedKeys];
                        });
     }];
}

#pragma mark Prepare to play asset

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
        /* If you are also implementing the use of -[AVAsset cancelLoading], add your code here to bail
         out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Generate an error describing the failure. */
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", nil);
        NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.",nil);
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
    
    /* At this point we're ready to set up for playback of the asset. */
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.playerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.playerItem removeObserver:self forKeyPath:kStatusKey];
        [self.playerItem removeObserver:self forKeyPath:kTracksKey];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.playerItem addObserver:self
                      forKeyPath:kStatusKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:PlayerItemStatusObserverContext];
    
    [self.playerItem addObserver:self
                      forKeyPath:kTracksKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:TrackObservationContext];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    
    /* Create new player, if we don't already have one. */
    if (![self player])
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:kRateKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:RateObservationContext];
        
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.playerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur*/
        [[self player] replaceCurrentItemWithPlayerItem:self.playerItem];
        
        //[self syncPlayPauseButtons];
    }
    
    //get Play Duration
    _totalDuration=CMTimeGetSeconds([self playerItemDuration:asset]);
    
    //设置字幕自动同步机制
    double interval = .2f;
    __weak typeof(self) weakSelf = self;
    
    self.playerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                    queue:NULL
                                                               usingBlock:
                           ^(CMTime time)
                           {
                               [weakSelf updateTimerFired];
                               
                           }];
}

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    /* AVPlayerItem "status" property value observer. */
    if (context == PlayerItemStatusObserverContext)
    {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
            case AVPlayerStatusUnknown:
            {
                /*
                [self.view makeToast:@"如果加载时间很长，建议离线后再使用：）"
                            duration:1
                            position:CSToastPositionCenter];
                
                [self  performSelector:@selector(autoReportLessonError) withObject:nil afterDelay:10];
                 */
            }
                break;
                
            case AVPlayerStatusReadyToPlay:
            {
                _timeScale = self.player.currentItem.asset.duration.timescale;
                
                if (_timeScale==0) {
                    _timeScale=NSEC_PER_SEC;
                }
                
                if (_firstPlaying) {
                    
                    //设置播放器初试时间
                    [self.player seekToTime:CMTimeMakeWithSeconds(_initialPlaybackTime, _timeScale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
                    
                    if (_needShareM3U8URL) {
                        
                        [self shareM3U8Url:_movieURLStr forLessonID:self.thePubLesson.lessonID];
                    }
                    
                    //加载完毕
                    [self hideLoadingIndicator];
                    [self preparePlayAndControlView];
                    
                    [self.playerView  setPlayer:self.player];
                    self.playerView.playerLayer.backgroundColor = [[UIColor blackColor] CGColor];
                    self.playerView.playerLayer.hidden = NO;
                    [self.playerView setVideoFillMode:AVLayerVideoGravityResizeAspect];
                }
                
                [self playAndDoAI];
            }
                break;
                
            case AVPlayerStatusFailed:
            {
                AVPlayerItem *thePlayerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:thePlayerItem.error];
            }
                break;
        }
    }
    /* AVPlayer "rate" property value observer. */
    else if (context == RateObservationContext)
    {
        if (self.player.rate==0) {
            
            [self showControlBar];
            
            if (self.player.status!=AVPlayerStatusReadyToPlay)
            {
                [self showLoadingIndicator];
            }
        }
        else{
            
            if( !(_contentType== BELocalMp3Audio || _contentType==BEWebMp3Audio) ){
                
                [self hideControlBar];
            }
            [self hideLoadingIndicator];
        }
    }
    /* AVPlayer "Track" property value observer. */
    else if (context == TrackObservationContext)
    {
        
    }
    else if (context == SubtitlStatusObserverContext){
        
        UITextView *tv = object;
        CGFloat topCorrect = ([tv bounds].size.height - [tv contentSize].height * [tv zoomScale])/2.0;
        topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
        tv.contentOffset = (CGPoint){.x = 0, .y = -topCorrect};
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
    
    return;
}

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    /* Display the error. */
    
    NSLog(@"move failed:%@", [error localizedDescription]);
    
    [self reportError];
}


-(void) autoReportLessonError
{
    
    if (self.player.currentItem.status==AVPlayerItemStatusFailed || self.player.currentItem.status==AVPlayerItemStatusUnknown) {
        [self reportError];
    }
}

-(void) reportError
{
    NSString * type;
    
    if ([NSString checkOfficialURL:_movieURLStr]) {
        
        type=@"err_m3u8";
    }
    else if (_needParserContentURL) {
        
        type=@"err_url1";
    }
    else{
        
        type=@"err_url2";
    }
    
    [AFHttpTool reportLessonErrorType:type
                           contentURL:_movieURLStr
                             lessonID:self.thePubLesson.lessonID
                              success:^(id response)
    {
        //
        NSString * tempStr =[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        
        if ([tempStr isEqualToString:@"10"] || [tempStr isEqualToString:@"11"])
        {
            NSString *message = NSLocalizedString(@"网速太慢,使劲加载中...",nil);
            iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate makeToast:message];
        }
        else
        {
            NSString *message = NSLocalizedString(@"我们正在处理你碰到的问题...",nil);
            iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate makeToast:message];
        }
        
    } failure:^(NSError *err) {
        //
        NSLog(@"reportLessonErrorType:%@",err.description);
    }];
}

//////////////////////////////////////////////////////////////
#pragma play control
//////////////////////////////////////////////////////////////

//添加播放控制手势
- (void)addPlayBaseControlGestureRecognizer
{
    // 单击的 Recognizer
    UITapGestureRecognizer *singleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapFrom:)];
    singleRecognizer.numberOfTapsRequired = 1; // 单击
    [self.gestureControlView addGestureRecognizer:singleRecognizer];
    
    // 双击的 Recognizer
    UITapGestureRecognizer *doubleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapFrom:)];
    doubleRecognizer.numberOfTapsRequired = 2; // 双击
    [self.gestureControlView addGestureRecognizer:doubleRecognizer];
    
    // 关键在这一行，如果双击确定偵測失败才會触发单击
    [singleRecognizer requireGestureRecognizerToFail:doubleRecognizer];
    
    // 右划的 Recognizer
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(handleRightSwipeTapFrom:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.gestureControlView addGestureRecognizer:rightSwipe];
    
    // 左划的 Recognizer
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleLeftSwipeTapFrom:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.gestureControlView addGestureRecognizer:leftSwipe];
    
    // 下划的 Recognizer
    UISwipeGestureRecognizer *downSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleDownSwipeTapFrom:)];
    downSwipe.direction = UISwipeGestureRecognizerDirectionDown;
    [self.gestureControlView addGestureRecognizer:downSwipe];
    
    // 上划的 Recognizer
    UISwipeGestureRecognizer *upSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(handleUpSwipeTapFrom:)];
    upSwipe.direction = UISwipeGestureRecognizerDirectionUp;
    [self.gestureControlView addGestureRecognizer:upSwipe];
}

#pragma mark - Player Touch Control/GestureRecognizer

//屏幕单击
- (void)handleSingleTapFrom: (id) sender
{
    if ([self playerIsReady]) {
        
        [self toggleButton];
    }
}

//屏幕双击
- (void)handleDoubleTapFrom: (id) sender
{
    [self doMagic];
}

//控制进度条出现
-(void) showControlBar
{
    self.buttonsView.alpha=1;
}

//控制进度条消失
- (void)hideControlBar
{
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        self.buttonsView.alpha=0;
        
    } completion:^(BOOL finished) {}];
}

- (void)showControlBarSomeTime
{
    self.buttonsView.alpha=1;
    
    [UIView animateWithDuration:2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        self.buttonsView.alpha=0;
        
    } completion:^(BOOL finished) {}];
}

//屏幕右划
- (void)handleRightSwipeTapFrom: (id) sender
{
    if (_subtitleFile)
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"BESwipRight"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSTimeInterval npt=0;
        NSUInteger index = self.subtitleTextView.currentSubtitleIndex;
        
        //学习字幕区
        if (index < _subtitleFile.countOfSubItems) {
            //第一个字幕回到开头
            if( index ==  0  ){
                //回退到开头
                npt=0;
            }
            else{
                //回退到上一个字幕
                npt=[[_subtitleFile  getSubItemForIndex:(index-1)] startTimeInSeconds];
            }
        }
        else{
            
            //如果现在无学习字幕或者空白play
            CMTime nowTime = self.player.currentTime;
            
            NSTimeInterval  freshTimeInSeconds = CMTimeGetSeconds(nowTime);
            
            NSUInteger afterIndex = [_subtitleFile idxAfterCurrentSubTime:freshTimeInSeconds];
            
            //片头回到开始
            if(afterIndex == 0){
                
                npt=0;//第一个字幕回到开头
            }
            else{
                
                if (afterIndex<_subtitleFile.countOfSubItems) {
                    //普通字幕空白区回到紧挨的上一个字幕开头
                    npt=[[_subtitleFile  getSubItemForIndex:(afterIndex-1)] startTimeInSeconds];
                }
                else{
                    
                    //最后的结束空白区，回到最后一个字幕开头
                    npt=[[_subtitleFile  getLastSubtitleItem] startTimeInSeconds];
                }
            }
        }
        //加0.2是为了修正计算误差导致跳转失灵
        [self seekToTime:(npt+0.2)];
    }
    else
    {
        CMTime nowTime = self.player.currentTime;
        NSTimeInterval  freshTimeInSeconds = CMTimeGetSeconds(nowTime);
        
        NSTimeInterval npt=freshTimeInSeconds-2;
        
        if (npt<0)
        {
            NSString *message = NSLocalizedString(@"已经播放完毕..",nil);
            iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate makeToast:message];
        }
        else
        {
            [self seekToTime:npt];
        }
    }
}

//屏幕左划
- (void)handleLeftSwipeTapFrom: (id) sender
{
    if(_subtitleFile)
    {
        NSTimeInterval npt=0;
        NSUInteger index = self.subtitleTextView.currentSubtitleIndex;
        
        //学习字幕区
        if (index < _subtitleFile.countOfSubItems) {
            
            if( index ==  (_subtitleFile.countOfSubItems-1) ){
                //跳转到片尾开头
                npt=[_subtitleFile getEndSubtitleTime]+0.1;
            }
            else{
                //跳转到下一个字幕
                npt=[[_subtitleFile  getSubItemForIndex:(index+1)] startTimeInSeconds];
            }
        }
        else
        {
            //如果现在无学习字幕或者空白play
            CMTime nowTime = self.player.currentTime;
            NSTimeInterval  freshTimeInSeconds = CMTimeGetSeconds(nowTime);
            NSUInteger afterIndex = [_subtitleFile idxAfterCurrentSubTime:freshTimeInSeconds];
            
            if(afterIndex<_subtitleFile.countOfSubItems){
                
                //普通字幕空白区跳转到紧挨的下一个字幕开头
                npt=[[_subtitleFile  getSubItemForIndex:afterIndex] startTimeInSeconds];
            }
        }
        //加0.2是为了修正计算误差导致跳转失灵
        [self seekToTime:(npt+0.2)];
    }
    else
    {
        CMTime nowTime = self.player.currentTime;
        NSTimeInterval  freshTimeInSeconds = CMTimeGetSeconds(nowTime);
        
        NSTimeInterval npt=freshTimeInSeconds+2;
        NSTimeInterval  duration = CMTimeGetSeconds(self.player.currentItem.duration);
        
        if (npt>duration)
        {
            NSString *message = NSLocalizedString(@"已经播放完毕..",nil);
            iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate makeToast:message];
        }
        else
        {
            [self seekToTime:npt];
        }
    }
}

//屏幕上划－－ 提高音量
- (void)handleUpSwipeTapFrom: (id) sender
{
    //[self.player setVolume:(self.player.volume+0.5)];
    
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    
    // retrieve system volume
    float systemVolume = volumeViewSlider.value;
    
    // change system volume, the value is between 0.0f and 1.0f
    [volumeViewSlider setValue:(systemVolume+0.15) animated:NO];
    
    // send UI control event to make the change effect right now.
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
}

//屏幕下划－－ 降低音量
- (void)handleDownSwipeTapFrom: (id) sender
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    UISlider* volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    
    // retrieve system volume
    float systemVolume = volumeViewSlider.value;
    
    // change system volume, the value is between 0.0f and 1.0f
    [volumeViewSlider setValue:(systemVolume-0.1) animated:NO];
    
    // send UI control event to make the change effect right now.
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void) playAndDoAI
{
    if (_firstPlaying) {
        
        _firstPlaying=NO;
    }
    //清理屏幕
    [self removeAllPersonalWordViews];
    //关闭放大镜
    [self.aiLearningView setAImagnifyEnabled:NO];
    
    if (_enableMagicGame)
    {
        //
    }
    else
    {
        //打开自动更新字幕
        _enableAutoUpdateSub=YES;
    }
    
    [self.player play];
}

- (void) pauseAndDoAI
{
    [self.player pause];

    if(_enableMagicGame)
    {
        [self.aiLearningView setAImagnifyEnabled:NO];
        
        //呈现进度条
        if ([self enableScrubber])
        {
            [self syncScrubber:self.timestamp];
        }
    }
    else
    {
        //关闭自动更新字幕
        _enableAutoUpdateSub=NO;
        
        NSInteger length = self.subtitleTextView.text.length;
        
        //如果有学习字幕，进行AI分析准备
        if (length!=0) {
            
            //开启放大镜
            if (self.subtitleTextView.text!=nil) {
                [self.aiLearningView setAImagnifyEnabled:YES];
            }
        }
        
        //呈现进度条
        if ([self enableScrubber])
        {
            [self syncScrubber:self.timestamp];
        }
    }
}

- (void)toggleButton
{
    if(self.player.rate != 0.f)
    {
        [self pauseAndDoAI];
        [self  showHintHelp];
    }
    else
    {
        [self playAndDoAI];
    }
}

- (void) seekToTime:(NSTimeInterval ) interval
{
    if(_enableMagicGame && _magicGameIndex != NSNotFound)
    {
        NSString *message = NSLocalizedString(@"闯关状态不能跳转哦：）",nil);
        iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate makeToast:message];
    }
    else
    {
        [self removeAllPersonalWordViews];
        
        if([self playerIsReady])
        {
            _timeScale = self.player.currentItem.asset.duration.timescale;
            
            [self.player seekToTime:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
                
                //暂停状态更新
                if (!self.isPlayingNow)
                {
                    [self updateSubtitle:interval];
                    [self syncScrubber:interval];
                }
                
            }];
        }
    }
}

- (void) stop
{
    if (_webView) {
        
        [_webView stopLoading];
        _webView=nil;
    }
    
    if (self.player) {
        
        [self.player pause];
        [self afterStopplaying];
    }
}

-(BOOL) isPlayingNow
{
    return self.player.rate!=0;
}

-(BOOL) hasSubtitleContent
{
    
    NSInteger length = self.subtitleTextView.text.length;
    
    return  length!=0;
}

#pragma mark - 进度条相关
/* The user is dragging the movie controller thumb to scrub through the movie. */
- (void)beginScrubbing:(id)sender
{
    [self.player setRate:0.f];
    
    //清理屏幕以及AI数据
    [self removeAllPersonalWordViews];
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (void)endScrubbing:(id)sender
{
    
    if (_contentType==BEWebMp4Vedio  || _contentType==BELocalMp4Vedio || _contentType==BEWebMp3Audio ||_contentType==BELocalMp3Audio )
    {
        
        [self playAndDoAI];
    }
}

/* Set the player current time to match the scrubber position. */
- (void)sliderChanged:(id)sender
{
    if (_enableMagicGame)
    {
        NSString *message = NSLocalizedString(@"闯关状态不能跳转哦：）",nil);
        iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate makeToast:message];
    }
    else
    {
        UISlider* slider = sender;
        
        if ([self playerIsReady])
        {
            _timeScale = self.player.currentItem.asset.duration.timescale;
            
            [self.player seekToTime:CMTimeMakeWithSeconds(_totalDuration*slider.value, _timeScale) completionHandler:^(BOOL finished) {
                
                //暂停状态 人为更新
                if (!self.isPlayingNow)
                {
                    [self updateSubtitle:_totalDuration*slider.value];
                    [self syncScrubber:_totalDuration*slider.value];
                }
            }];
        }
    }
 }

/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
    if (self.playerObserver)
    {
        [self.player removeTimeObserver:self.playerObserver];
        self.playerObserver = nil;
    }
}

- (NSString*) timeformatFromSeconds:(NSInteger)seconds
{
    if(seconds/3600==0)
    {
        //format of minute
        NSString *str_minute  = [NSString stringWithFormat:@"%02ld",(long)(seconds%3600)/60];
        //format of second
        NSString *str_second  = [NSString stringWithFormat:@"%02ld",(long)seconds%60];
        //format of time
        NSString *format_time = [NSString stringWithFormat:@"%@:%@",str_minute,str_second];
        return format_time;
    }
    else
    {
        //format of hour
        NSString *str_hour    = [NSString stringWithFormat:@"%02ld",(long)seconds/3600];
        
        //format of minute
        NSString *str_minute  = [NSString stringWithFormat:@"%02ld",(long)(seconds%3600)/60];
        //format of second
        NSString *str_second  = [NSString stringWithFormat:@"%02ld",(long)seconds%60];
        //format of time
        NSString *format_time = [NSString stringWithFormat:@"%@:%@:%@",str_hour,str_minute,str_second];
        
        return format_time;
    }
}


#pragma mark - Player Control Related

//播放准备ok后，增加字幕控制图层
- (void)prepareControlAndAI
{
    //更新播放时间数据
    [_lessonDAO updateDuration:_totalDuration LessonID:_lessonData.BELESSONID];
    
    //增加基本控制手势
    [self showControlBar];
    
    //添加字幕和智能学习内容
    NSString *subfileURLStr = _lessonData.localURLOfSub;
    if (![[NSFileManager defaultManager] fileExistsAtPath:subfileURLStr]){
        
        //如果是网络地址从网络请求字幕
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self getSrtFromBE];
        });
    }
    else{
        
        _subtitleFile=[[FlyingSubTitle alloc] initWithFile:subfileURLStr];
        
        if (_subtitleFile) {
            
            //准备词法分析工具
            [self prepareNLP];
            
//            _enableAISub=YES;
            self.subtitleTextView.hidden=NO;
            self.magicImageView.hidden=NO;
        }
        else{
//            _enableAISub=NO;
            self.subtitleTextView.hidden=YES;
            self.magicImageView.hidden=YES;
        }
    }
}

// 自然结束播放后，退回原先的界面
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    if (_enableMagicGame)
    {
        [self endMagicGame];
        if (self.delegate && [self.delegate respondsToSelector:@selector(endMagicGameByPlayer:)])
        {
            [self.delegate endMagicGameByPlayer:YES];
        }
    }
    
    self.timestamp=0;
    [self seekToTime:0];
}

//课程结束，进行相关处理
- (void)afterStopplaying
{
    //[self.subtitleTextView removeObserver:self forKeyPath:@"contentSize"];
    
    [self.playerItem  removeObserver:self forKeyPath:kStatusKey];
    [self.playerItem  removeObserver:self forKeyPath:kTracksKey];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.playerItem];

    
    [self.player  removeObserver:self     forKeyPath:kRateKey];
    [self.player  removeTimeObserver:self.playerObserver];
    [self.player  replaceCurrentItemWithPlayerItem:nil];
    
}

#pragma mark - Timer Fire (Subtitle Upate and play time update)

- (void)updateTimerFired
{
    @autoreleasepool
    {
        [self updateSubtitleForTimerFired];
//        [self syncScrubber:CMTimeGetSeconds(self.player.currentTime)];
    }
}

-(BOOL)enableScrubber
{
    if (_totalDuration==0 || _totalDuration!=_totalDuration)
    {
        return NO;
    }
    else
    {
        self.slider.value= self.timestamp/_totalDuration;
        self.slider.userInteractionEnabled = YES;
        
        return YES;
    }
}

- (CMTime)playerItemDuration:(AVURLAsset*) asset
{
    AVPlayerItem *thePlayerItem = [self.player currentItem];
    if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        
        return([self.playerItem duration]);
    }
    else{
        
        return asset.duration;
    }
}

-(BOOL) playerIsReady
{
    
    AVPlayerItem *thePlayerItem = [self.player currentItem];
    if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        return YES;
    }
    else{
        return NO;
    }
}

/* Set the scrubber based on the player current time. */
- (void)syncScrubber:(NSTimeInterval) time
{
    
    NSTimeInterval  freshTimeInSeconds;
    
    if (time==0) {
        
        if([self playerIsReady]){
            
            CMTime nowTime = self.player.currentTime;
            freshTimeInSeconds = CMTimeGetSeconds(nowTime);
        }
        else{
            
            freshTimeInSeconds = 0.0;
        }
    }
    else{
        
        freshTimeInSeconds=time;
    }
    
    self.timeLabel.text=[NSString stringWithFormat:@"%@/%@", [self timeformatFromSeconds:freshTimeInSeconds],[self timeformatFromSeconds:_totalDuration]];
    [self.slider setValue:freshTimeInSeconds/(_totalDuration*1.00) animated:YES];
}

- (void)updateSubtitleForTimerFired
{
    if (_enableMagicGame)
    {
        if(self.isPlayingNow && _magicGameIndex!=NSNotFound)
        {
            NSTimeInterval freshTimeInSeconds=0;
            
            if([self playerIsReady])
            {
                CMTime nowTime = self.player.currentTime;
                freshTimeInSeconds = CMTimeGetSeconds(nowTime);
            }
            
            FlyingSubRipItem * currentSubItem =[_subtitleFile getSubItemForIndex:_magicGameIndex];
            
            if (freshTimeInSeconds>currentSubItem.endTimeInSeconds+3)
            {
                if([self playerIsReady])
                {
                    _timeScale = self.player.currentItem.asset.duration.timescale;
                    
                    NSTimeInterval interval = currentSubItem.startTimeInSeconds-3;
                    
                    if (interval<0)
                    {
                        interval=0;
                    }
                    
                    [self.player seekToTime:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
                        //
                    }];
                }
            }
        }
    }
    else
    {
        if (_enableAutoUpdateSub)
        {
            NSTimeInterval freshTimeInSeconds=0;
            
            if([self playerIsReady]){
                
                CMTime nowTime = self.player.currentTime;
                freshTimeInSeconds = CMTimeGetSeconds(nowTime);
            }
            
            [self updateSubtitle:freshTimeInSeconds];
        }
    }
}

- (void) updateSubtitleWith:(NSMutableAttributedString * ) styleSentence
{
    [self.subtitleTextView setAttributedText:styleSentence];
    [self.subtitleTextView setTextAlignment:NSTextAlignmentCenter];
}

- (void)setMagicGameAt:(NSInteger) index;
{
    if (index==_subtitleFile.countOfSubItems)
    {
        _magicGameIndex= NSNotFound;
    }
    else
    {
        _magicGameIndex=index;
        
        if (!self.isPlayingNow)
        {
            [self play];
        }
    }
}

- (void) endMagicGame
{
    _enableMagicGame=NO;
    self.magicImageView.image = [UIImage imageNamed:@"off"];
    [self.aiLearningView setAImagnifyEnabled:YES];
    [self.subtitleTextView setHidden:NO];
}

- (void)updateSubtitle:(NSTimeInterval) freshTimeInSeconds
{
    [self setTimestamp:freshTimeInSeconds];//更新时间戳
    
    if (_subtitleFile)
    {
        NSUInteger freshIndex = [_subtitleFile idxOfSubItemWithSubTime:freshTimeInSeconds];
        
        //当前字幕无需更新,用来解析智能字幕
        if (freshIndex==self.subtitleTextView.currentSubtitleIndex)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self nplSubtitleWhatEver];
                return;
            });
        }
        
        //如果现在是字幕时间
        if(freshIndex != NSNotFound)
        {
            //取得更新字幕内容
            [self showAutoAIContent:freshIndex];
        }
        //空白字幕区
        else{
            
            //片头字幕区
            if (freshTimeInSeconds < ([_subtitleFile getStartSubtitleTime]-1) ) {
                
                [self.subtitleTextView setText:@""];
                
            }
            else{
                
                if ( freshTimeInSeconds > [_subtitleFile getEndSubtitleTime] ) {
                    
                    [self.subtitleTextView setText:@""];
                }
                else{
                    //延迟字幕一秒钟,不更新
                    if (freshTimeInSeconds<[_subtitleFile getSubItemForIndex:self.subtitleTextView.currentSubtitleIndex].endTimeInSeconds+2) {
                        freshIndex= self.subtitleTextView.currentSubtitleIndex;
                    }
                    else{
                        //超过一秒，更新字幕为空
                        [self.subtitleTextView setText:nil];
                    }
                }
            }
        }
        //更新字幕索引
        self.subtitleTextView.currentSubtitleIndex = freshIndex;
    }
}

#pragma mark - AI show

-(void) prepareNLP
{
    //准备存储NPL结果
    self.subtitleAIDic = [NSMutableDictionary dictionaryWithCapacity:_subtitleFile.countOfSubItems];
    self.currentAIIndex = -1;
    
    //准备注释视图
    if (_annotationWordViews==NULL) _annotationWordViews = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    //准备放大镜
    if (_mag==Nil) {
        _mag= [[ACMagnifyingGlass alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
        _mag.scale = 2;
        self.aiLearningView.magnifyingGlass = _mag;
    }
}

- (void) showAutoAIContent:(NSInteger) freshIndex
{
    FlyingSubRipItem * currentSubItem =[_subtitleFile getSubItemForIndex:freshIndex];

    //没有字幕
    if (!currentSubItem.text)
    {
        return;
    }
    
    //没有AI处理就先处理
    if (!self.subtitleAIDic[currentSubItem.text])
    {
        [self nplSubtitle:freshIndex];
    }
    
    NSArray * wordArray =  [[[FlyingTaskWordDAO alloc] init] selectWordsWithUserID:_currentPassport];

    if (wordArray.count!=0)
    {
        NSArray  * tagAndTokens = self.subtitleAIDic[currentSubItem.text];
        
        if (tagAndTokens)
        {
            //自动显示学习目标内的学习单词            
            UIFont * tempFont = self.subtitleTextView.font;
            
            //设置默认生词白色，system 20 大小
            __block NSArray* objects = [[NSArray  alloc] initWithObjects:tempFont, [UIColor whiteColor], nil];
            __block NSArray* keys    = [[NSArray  alloc] initWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, nil];
            
            NSDictionary *defaultFont = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            NSMutableAttributedString * styleSentence =[[NSMutableAttributedString alloc] initWithString:currentSubItem.text attributes:defaultFont];
            
            [tagAndTokens enumerateObjectsUsingBlock:^(FlyingWordLinguisticData * theTagWord, NSUInteger idx, BOOL *stop) {
                
                //用词性色代替背景色
                UIColor * wordColor = [UIColor whiteColor];
                UIColor * backgroundColor = [UIColor clearColor];
                
                if ([wordArray containsObject:[theTagWord  getLemma]]) {
                    
                    backgroundColor=[_tagTransform corlorForTag:theTagWord.tag];
                    
                    if (theTagWord.tag == NSLinguisticTagAdjective || theTagWord.tag == NSLinguisticTagPronoun) {
                        wordColor = [UIColor blackColor];
                    }
                }
                
                objects = [[NSArray  alloc] initWithObjects:tempFont,backgroundColor, wordColor, nil];
                keys    = [[NSArray  alloc] initWithObjects:NSFontAttributeName, NSBackgroundColorAttributeName, NSForegroundColorAttributeName,nil];
                
                NSDictionary *attrs = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
                [styleSentence  setAttributes:attrs range:theTagWord.tokenRange];
                [self.subtitleTextView setAttributedText:styleSentence];
                [self.subtitleTextView setTextAlignment:NSTextAlignmentCenter];
            }];
        }
    }
    else
    {
        self.subtitleTextView.text = currentSubItem.text;
    }
}

#pragma mark - Annatation related

//得到单词在AILearingView中的位置
-(CGRect) getWordLocationForAIview:(NSRange) range
{
    if (range.length == 0) {
        return  CGRectMake(0, 0, 0, 0);
    }
    
    UITextPosition *beginning = self.subtitleTextView.beginningOfDocument;
    UITextPosition *start = [self.subtitleTextView positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [self.subtitleTextView positionFromPosition:start offset:range.length];
    
    UITextRange *textRange = [self.subtitleTextView textRangeFromPosition:start toPosition:end];
    CGRect rect = [self.subtitleTextView firstRectForRange:textRange];
    
    if (rect.size.width == 0) {
        return  CGRectMake(0, 0, 0, 0);
    }
    
    return [self.subtitleTextView.textInputView  convertRect:rect toView:self.aiLearningView];
}

#pragma mark - Personal Wordview Related

-(void) showViewForWord: (FlyingWordLinguisticData *) tagWord
{
    FlyingItemView * aTagWordView = [_annotationWordViews objectForKey:[tagWord getIDKey]];
    
    if (!aTagWordView) {
        
        CGRect frame=CGRectMake(0, 0, 160, 160);
        
        if (INTERFACE_IS_PAD || !self.toFullScreen) {
            
            frame=CGRectMake(0, 0, 200, 200);
        }
        
        aTagWordView =[[FlyingItemView alloc] initWithFrame:frame];
        if (!self.toFullScreen) {
            
            aTagWordView.fullScreenModle=YES;
        }
        
        [aTagWordView setLessonID:self.thePubLesson.lessonID];
        
        [aTagWordView setWord:[self.subtitleTextView.text substringWithRange:tagWord.tokenRange]];
        [aTagWordView  drawWithLemma:tagWord.getLemma AppTag:tagWord.tag];
        aTagWordView.delegate = self;
        
        //纪录下来,为了复用
        [_annotationWordViews setObject:aTagWordView forKey:[tagWord getIDKey]];
    }
    
    //显示磁贴单词图
    [self showSinglelWordView:aTagWordView];
}

-(void) showSinglelWordView: (FlyingItemView *) personalWordView
{
    if (!personalWordView.superview) {
        
        //随机散开磁贴的显示位置
        srand((unsigned int)personalWordView.lemma.hash);
        
        CGFloat x = (self.aiLearningView.frame.size.width-personalWordView.frame.size.width)*rand()/(RAND_MAX+1.0);
        CGFloat y=  (self.aiLearningView.frame.size.height-self.subtitleTextView.frame.size.height-personalWordView.frame.size.height)*rand()/(RAND_MAX+1.0);
        
        personalWordView.frame =CGRectMake(x, y, personalWordView.frame.size.width, personalWordView.frame.size.height) ;
        
        [personalWordView adjustForAutosizing];
        [self.aiLearningView addSubview:personalWordView];
        
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            
            personalWordView.alpha=1;
            
        } completion:^(BOOL finished) {}];
    }
    else{
        
        [personalWordView.superview bringSubviewToFront:personalWordView];
    }
}

- (void) removeAllPersonalWordViews
{
    if (_annotationWordViews.count != 0) {
        
        for (FlyingItemView * object in [_annotationWordViews allValues]) {
            
            [object dismissViewAnimated:YES];
        }
    }
    [_annotationWordViews removeAllObjects];
}

- (void) itemPressed:(NSString*)lemma
{
    FlyingWordDetailVC * wordDetail =[[FlyingWordDetailVC alloc] init];
    [wordDetail setTheWord:lemma];
    
    [self.navigationController pushViewController:wordDetail animated:YES];
}

#pragma mark - 字幕相关手势 FlyingAILearningViewDelegate

//手指接触字幕后，AI高亮显示选中单词
- (void) touchOnSubtileBegin: (CGPoint) touchPoint
{
    
    //纪录当前点击位置单词
    FlyingWordLinguisticData * theTagWord = [self getWordForTouch:touchPoint];
    
    if (theTagWord) {
        
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"BEHelpSubtitleTouch"]){
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"BEHelpSubtitleTouch"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        [self showAIColorForWord:theTagWord];
        
        [_speechPlayer speechWord:theTagWord.word LessonID:self.thePubLesson.lessonID];
    }
    
    //纪录当前单词，规避重复刷新
    _theOnlyTagWord=theTagWord;
}

//手指在字幕上移动，AI高亮显示选中单词
- (void) touchOnSubtileMoved: (CGPoint) touchPoint
{
    
    //在当前点击位置显示单词简单解释
    FlyingWordLinguisticData * theTagWord = [self getWordForTouch:touchPoint];
    
    if (theTagWord) {
        
        if (theTagWord!=_theOnlyTagWord) {
            
            [self showAIColorForWord:theTagWord];
            [_speechPlayer speechWord:theTagWord.getLemma LessonID:self.thePubLesson.lessonID];
            
            _theOnlyTagWord=theTagWord;
        }
    }
}

//手指离开字幕后，直接显示选中单词解释
- (void) touchOnSubtileEnd: (CGPoint) touchPoint
{
    if (_theOnlyTagWord) {
        
        [self showViewForWord:_theOnlyTagWord];
                
        //纪录重点单词
        [self addToucLammaRecord:_theOnlyTagWord Sentence:self.subtitleTextView.text];
    }
}

- (void) touchOnSubtileCancelled: (CGPoint) touchPoint
{
    
    if (_theOnlyTagWord) {
        
    }
    
    _theOnlyTagWord=nil;
}

- (void) doMagic
{
    if (!self.toFullScreen)
    {
        NSString *title = @"友情提醒";
        NSString *message = @"全屏模式不能进行闯关模式";
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        }];
        
        [alertController addAction:doneAction];
        [self presentViewController:alertController animated:YES completion:^{
            //
        }];
        
        return;
    }
    
    
    if (_subtitleFile)
    {
        if (_enableMagicGame)
        {
            _enableMagicGame=NO;
            self.magicImageView.image = [UIImage imageNamed:@"off"];
            [self.aiLearningView setAImagnifyEnabled:YES];
            [self.subtitleTextView setHidden:NO];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(endMagicGameByPlayer:)])
            {
                [self.delegate endMagicGameByPlayer:YES];
            }
        }
        else
        {
            if([self playerIsReady])
            {
                NSTimeInterval freshTimeInSeconds=0;
                
                CMTime nowTime = self.player.currentTime;
                freshTimeInSeconds = CMTimeGetSeconds(nowTime);
                
                //获取当前时间的字幕索引
                _magicGameIndex =[_subtitleFile idxOfSubItemWithSubTime:freshTimeInSeconds];
                
                //空白字幕区，获取下一个字幕区间
                if (_magicGameIndex==NSNotFound)
                {
                    _magicGameIndex =[_subtitleFile idxAfterCurrentSubTime:freshTimeInSeconds];
                }
                
                if (_magicGameIndex !=NSNotFound)
                {
                    _enableMagicGame=YES;
                    self.magicImageView.image = [UIImage imageNamed:@"on"];
                    [self.aiLearningView setAImagnifyEnabled:NO];
                    [self.subtitleTextView setHidden:YES];
                    
                    if (self.delegate && [self.delegate respondsToSelector:@selector(playGameForSub:GameIndex:)])
                    {
                        [self.delegate playGameForSub:_subtitleFile GameIndex:_magicGameIndex];
                    }
                }
            }
        }
    }
    
//    if (self.subtitleTextView.isHidden) {
//        
//        _enableAISub=YES;
//        [self.subtitleTextView setHidden:NO];
//        
//        [self.aiLearningView setAImagnifyEnabled:YES];
//        
//        self.magicImageView.image = [UIImage imageNamed:@"off"];
//    }
//    else{
//        
//        _enableAISub=NO;
//        
//        [self.subtitleTextView setHidden:YES];
//        
//        [self.aiLearningView setAImagnifyEnabled:NO];
//        
//        self.magicImageView.image = [UIImage imageNamed:@"on"];
//    }
}

//得到点击位置单词，位置以AIlearningView坐标为准
-(FlyingWordLinguisticData *) getWordForTouch:( CGPoint) touchPoint
{
    
    if (self.subtitleTextView.text) {
        
        NSArray *tagAndTokens = self.subtitleAIDic[self.subtitleTextView.text];
        
        //判断点击位置的单词
        for (FlyingWordLinguisticData * object in tagAndTokens) {
            
            if(CGRectContainsPoint([self getWordLocationForAIview:object.tokenRange],touchPoint))
                
                return object;
        }
    }
    
    return nil;
}

#pragma mark - Flying Magic NLP & AIColor

-(void) nplSubtitle:(NSInteger) index
{
    FlyingSubRipItem * currentSubItem = [_subtitleFile getSubItemForIndex:index];
    
    //有字幕
    if (currentSubItem.text)
    {
        //没有AI处理，就可以处理
        if (!self.subtitleAIDic[currentSubItem.text])
        {
            iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableArray * tagAndTokens =[appDelegate nplString:currentSubItem.text];
            
            //有处理结果
            if (tagAndTokens)
            {
                [self.subtitleAIDic setObject:tagAndTokens forKey:currentSubItem.text];
            }
        }
    }
}

-(void) nplSubtitleWhatEver
{
    //处理下一个字幕
    self.currentAIIndex++;
    
    FlyingSubRipItem * currentSubItem = [_subtitleFile getSubItemForIndex:self.currentAIIndex];
    
    //有可以处理的字幕
    if (currentSubItem.text) {
        
        //没有AI处理，就可以处理
        if (!self.subtitleAIDic[currentSubItem.text])
        {
            iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
            NSMutableArray * tagAndTokens =[appDelegate nplString:currentSubItem.text];
            
            //有处理结果
            if (tagAndTokens)
            {
                [self.subtitleAIDic setObject:tagAndTokens forKey:currentSubItem.text];
            }
        }
    }
}

//6.0版本机器支持彩色显示AI单词
-(void) showAIColorForWord:(FlyingWordLinguisticData *) theTagWord
{
    //空字幕不需要再进行智能解析
    if (theTagWord==Nil){
        return;
    }
    
    UIFont * tempFont = self.subtitleTextView.font;
    
    //设置默认生词白色，system 20 大小
    NSArray* objects = [[NSArray  alloc] initWithObjects:tempFont, [UIColor whiteColor], nil];
    NSArray* keys    = [[NSArray  alloc] initWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, nil];
    
    NSDictionary *defaultFont = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    NSMutableAttributedString * styleSentence =[[NSMutableAttributedString alloc] initWithString:self.subtitleTextView.text attributes:defaultFont];
    
    //用词性色代替背景色
    UIColor * wordColor = [UIColor whiteColor];
    if (theTagWord.tag == NSLinguisticTagAdjective || theTagWord.tag == NSLinguisticTagPronoun) {
        wordColor = [UIColor blackColor];
    }
    
    objects = [[NSArray  alloc] initWithObjects:tempFont, [_tagTransform corlorForTag:theTagWord.tag], wordColor, nil];
    keys    = [[NSArray  alloc] initWithObjects:NSFontAttributeName, NSBackgroundColorAttributeName, NSForegroundColorAttributeName,nil];
    
    NSDictionary *attrs = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    [styleSentence  setAttributes:attrs range:theTagWord.tokenRange];
    [self.subtitleTextView setAttributedText:styleSentence];
    [self.subtitleTextView setTextAlignment:NSTextAlignmentCenter];
}

#pragma mark - Save Data related

//把点击重点单词纪录下来
-(void) addToucLammaRecord:(FlyingWordLinguisticData *) touchWord  Sentence:(NSString*) sentence
{
    
    dispatch_async(_background_queue, ^{
        
        FlyingTaskWordDAO * taskWordDAO   = [[FlyingTaskWordDAO alloc] init];
        
        //保存截图(例句视频不截图)
        if (_contentType==BELocalMp4Vedio || _contentType==BEWebMp4Vedio) {
            
            [self screenCopyWord:touchWord.getLemma];
        }
        
        [taskWordDAO insertWithUesrID:_currentPassport
                                 Word:touchWord.getLemma
                             Sentence:sentence
                             LessonID:self.thePubLesson.lessonID];
    });
}

#pragma mark - Flying back

//back delegate functions
- (void)dismiss
{
    
    [self stop];
}

//从网络获取字幕
- (void) getSrtFromBE
{
    if(_lessonData.BEOFFICIAL)
    {
        [AFHttpTool lessonResourceType:kResource_Sub
                              lessonID:self.thePubLesson.lessonID
                            contentURL:nil
                                 isURL:NO
                               success:^(id response) {
                                   //
                                   [self dealWithSrtData:response];
                               } failure:^(NSError *err) {
                                   //
                                   NSLog(@"getSrtFromBE:%@",err.description);
                               }];
    }
    else
    {
        //用文件指纹获取
    }
}

-(void) dealWithSrtData:(NSData *) data
{
    NSString * temStr =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSRange segmentRange = [temStr rangeOfString:@"所请求映射类文件不存在"];
    
    if ( (segmentRange.location==NSNotFound) && (data!=nil) ) {
        
        [data writeToFile:_lessonData.localURLOfSub atomically:YES];
        
        _subtitleFile=[[FlyingSubTitle alloc] initWithData:data];
        
        if (_subtitleFile){
            
            //准备词法分析工具
            [self prepareNLP];
            
//            _enableAISub=YES;
            self.subtitleTextView.hidden=NO;
            self.magicImageView.hidden=NO;
        }
        else{
//            _enableAISub=NO;
            self.subtitleTextView.hidden=YES;
            self.magicImageView.hidden=YES;
        }
    }
    else
    {
        NSString *message = NSLocalizedString(@"没有字幕,不能智能学习..",nil);
        iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate makeToast:message];
//        _enableAISub=NO;
    }
}

-(void)showHintHelp
{
    if(_subtitleFile)
    {
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"BESwipRight"])
        {
            NSString *message = NSLocalizedString(@"右划跳转到上一个场景!",nil);
            iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate makeToast:message];
        }
    }
}

-(void) screenCopyWord:(NSString*) word
{
    AVAsset *myAsset = self.player.currentItem.asset;
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:myAsset];
    
    CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:self.player.currentTime actualTime:nil error:nil];
    
    if (halfWayImage != NULL) {
        
        NSString * wordPicURL =[NSString picPathForWord:word];
        UIImage *screen=[UIImage imageWithCGImage:halfWayImage];
        
        //如果没有图片文件就创建一个
        if (![[NSFileManager defaultManager] fileExistsAtPath:wordPicURL]){
            [[NSFileManager defaultManager] createFileAtPath:wordPicURL contents:nil attributes:nil];
        }
        
        [UIImageJPEGRepresentation([screen  makeThumbnailOfSize:self.view.bounds.size],0) writeToFile:wordPicURL atomically:YES];
        // Do something interesting with the image.
        CGImageRelease(halfWayImage);
    }
}

//////////////////////////////////////////////////////////////
#pragma mark - M3U8 Related
//////////////////////////////////////////////////////////////

-(void) getContentUrlFronWeb
{
    //目前只有动态获取M3U8这一种情况！！！！！
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        _webView.scalesPageToFit   = NO;
        _webView.delegate          = self;
        _webView.dataDetectorTypes = UIDataDetectorTypeNone;
        
        if(_lessonData.BECONTENTURL)
        {
            NSURL *url =[[NSURL alloc] initWithString:_lessonData.BECONTENTURL];
            NSURLRequest *request =  [[NSURLRequest alloc] initWithURL:url];
            [_webView loadRequest:request];
        }
    });
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    _parseContentURLOK=NO;
    //取页面M3U8
    NSString * lJs2 = @"(document.getElementsByTagName(\"video\")[0]).src";  // youku,tudou,ku6 ,souhu
    NSString * lm3u8 = [webView stringByEvaluatingJavaScriptFromString:lJs2];
    
    NSRange textRange;
    NSString * substring= @"m3u8";
    textRange =[lm3u8 rangeOfString:substring];
    
    if(textRange.location != NSNotFound)
    {
        _movieURLStr =lm3u8;
        _contentType=BEWebM3U8Vedio;
        
        _parseContentURLOK=YES;
        
        if (INTERFACE_IS_PAD) {
            _needShareM3U8URL=NO;
        }
        else{
            _needShareM3U8URL=YES;
        }
        _webView=nil;
        [self prepareAVPlayer];
    }
}

//分享M3U8--URL
- (void) shareM3U8Url:(NSString*) m3u8URL  forLessonID:(NSString *) lessonID
{
    [AFHttpTool shareContentUrl:m3u8URL
                    contentType:@"m3u8_o"
                    forLessonID:lessonID
                        success:^(id response) {
                            //
                            NSString * msg=[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
                            NSLog(@"分享M3U8 succeess is:%@",msg);
                            
                        } failure:^(NSError *err) {
                            //
                            NSLog(@"web answer is%@",err.description);
                        }];
}

#pragma only UI events
//////////////////////////////////////////////////////////////
- (void)doSwitchFullScreen
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(doSwitchToFullScreen:)])
    {
        [self.delegate doSwitchToFullScreen:self.toFullScreen];
        
        if(self.toFullScreen)
        {
            [self endMagicGame];
            if (self.delegate && [self.delegate respondsToSelector:@selector(endMagicGameByPlayer:)])
            {
                [self.delegate endMagicGameByPlayer:YES];
            }
        }
        
        self.toFullScreen=!self.toFullScreen;
    }
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return   UIInterfaceOrientationLandscapeRight;
}



-(UIImage*) OriginImage:(UIImage*)image scaleToSize:(CGSize)size

{
    UIGraphicsBeginImageContext(size);//size为CGSize类型，即你所需要的图片尺寸
    
    [image drawInRect:CGRectMake(0,0, size.width, size.height)];
    
    UIImage* scaledImage =UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;
}


+ (UIImage*) thumbnailImageForMp3:(NSURL *)mp3fURL
{
    
    AVAsset *assest = [AVURLAsset URLAssetWithURL:mp3fURL options:nil];
    
    for (NSString *format in [assest availableMetadataFormats]) {
        
        for (AVMetadataItem *item in [assest metadataForFormat:format]) {
            
            if ([[item commonKey] isEqualToString:@"artwork"]) {
                UIImage *img = nil;
                if ([item.keySpace isEqualToString:AVMetadataKeySpaceiTunes]) {
                    img = [UIImage imageWithData:[item.value copyWithZone:nil]];
                }
                else { // if ([item.keySpace isEqualToString:AVMetadataKeySpaceID3]) {
                    NSData *data = [(NSDictionary *)[item value] objectForKey:@"data"];
                    img = [UIImage imageWithData:data]  ;
                }
                
                return img;
            }
        }
    }
    
    return nil;
}

+ (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60) actualTime:NULL error:&thumbnailImageGenerationError];
    
    if (!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    
    UIImage *thumbnailImage = thumbnailImageRef ? [UIImage imageWithCGImage:thumbnailImageRef] : nil;
    
    return thumbnailImage;
}

@end