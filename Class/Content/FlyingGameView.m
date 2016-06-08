//
//  FlyingGameView.m
//  FlyingEnglish
//
//  Created by vincent sung on 29/5/2016.
//  Copybottom © 2016 BirdEngish. All bottoms reserved.
//

#import "FlyingGameView.h"
#import "iFlyingAppDelegate.h"
#import "FlyingWordLinguisticData.h"
#import "FlyingSoundPlayer.h"
#import "FlyingSubRipItem.h"
#import "NSString+FlyingExtention.h"
#import "D3View.h"
#import "FlyingDataManager.h"

@interface FlyingGameView()

@property (strong,nonatomic) CAEmitterLayer *fireworksEmitter;

@property (strong,nonatomic) FlyingSubTitle*  subtitle;
@property (strong,nonatomic) NSArray * sortedSubItems;
@property (assign,nonatomic) NSInteger gameIndex;

@property (strong,nonatomic) NSSet   * notKeyWords;

@end

@implementation FlyingGameView

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    // Initialization code
    [self _setup];
}

+ (FlyingGameView*) gameView
{
    return [[[NSBundle mainBundle] loadNibNamed:@"FlyingGameView" owner:self options:nil] firstObject];
}

- (void)_setup
{
    self.backgroundColor = [UIColor clearColor];
    
    UITapGestureRecognizer *topRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchtop)];
    topRecognizer.numberOfTapsRequired = 1; // 单击
    [self.topTextView addGestureRecognizer:topRecognizer];
    
    UITapGestureRecognizer *bottomRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchbottom)];
    bottomRecognizer.numberOfTapsRequired = 1; // 单击
    [self.bottomTextView addGestureRecognizer:bottomRecognizer];
    self.bottomTextView.userInteractionEnabled = YES;
    
    self.notKeyWords = [NSSet setWithObjects:@"be",@"do",@"has",@"have",@"will",@"'re",@"'m",@"'d",@"'s",@"'ve",@"'ll",nil];
}

-(void) loadSubtitle:(FlyingSubTitle *) subtitle
{
    if (!self.subtitle)
    {
        self.subtitle = subtitle;
        
        self.sortedSubItems = [[self.subtitle allSubItems] sortedArrayUsingComparator:^NSComparisonResult(FlyingSubRipItem* a, FlyingSubRipItem* b) {
            
            return a.text.length>b.text.length;
        }];
    }
}

-(void) beginGameAtIndex:(NSInteger) index
{
    self.gameIndex = index;
    
    if (index<self.sortedSubItems.count)
    {
        FlyingSubRipItem * aItem =[self.subtitle getSubItemForIndex:index];
        __block FlyingSubRipItem * bItem;
        
        [self.sortedSubItems enumerateObjectsUsingBlock:^(FlyingSubRipItem *  obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([obj.index isEqualToString:aItem.index]) {
                
                *stop=YES;
                
                if (idx==self.sortedSubItems.count-1)
                {
                    
                    bItem =self.sortedSubItems[idx-2];
                }
                else
                {
                    bItem =self.sortedSubItems[idx+1];
                }
            }
        }];
        
        int tmp = (arc4random() % 100);
        if(tmp < 50)
        {
            [self.topTextView setAttributedText:[self getKeyPointSentece:aItem.text]];
            [self.topTextView setIndex:aItem.index];
            
            [self.bottomTextView setAttributedText:[self getKeyPointSentece:bItem.text]];
            [self.bottomTextView setIndex:bItem.index];
        }
        else
        {
            [self.topTextView setAttributedText:[self getKeyPointSentece:bItem.text]];
            [self.topTextView setIndex:bItem.index];

            [self.bottomTextView setAttributedText:[self getKeyPointSentece:aItem.text]];
            [self.bottomTextView setIndex:aItem.index];
        }
    }
}

-(NSMutableAttributedString *) getKeyPointSentece:(NSString*) sentence
{
    if ([NSString isBlankString:sentence]) {
        
        return nil;
    }
    
    iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray * tagAndTokens =[appDelegate nplString:sentence];
    
    //组装新字幕
    //设置默认字幕颜色和字体
    __block UIFont * tempFont = [UIFont systemFontOfSize:KLargeFontSize];
    
    __block NSArray* objects = [[NSArray  alloc] initWithObjects:tempFont, [UIColor grayColor], nil];
    __block NSArray* keys    = [[NSArray  alloc] initWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, nil];
    
    NSDictionary *defaultFont = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    NSMutableAttributedString * styleSentence =[[NSMutableAttributedString alloc] initWithString:sentence attributes:defaultFont];
    
    [tagAndTokens enumerateObjectsUsingBlock:^(FlyingWordLinguisticData * theTagWord, NSUInteger idx, BOOL *stop) {
        
        //用词性色代替背景色
        UIColor * wordColor = [UIColor whiteColor];
        UIColor * backgroundColor = [UIColor clearColor];
        
        if ([NSLinguisticTagNoun isEqualToString:theTagWord.tag]||
            [NSLinguisticTagVerb isEqualToString:theTagWord.tag]||
            [NSLinguisticTagAdjective isEqualToString:theTagWord.tag]||
            [NSLinguisticTagPersonalName isEqualToString:theTagWord.tag]||
            [NSLinguisticTagPlaceName isEqualToString:theTagWord.tag]||
            [NSLinguisticTagOrganizationName isEqualToString:theTagWord.tag]||
            [NSLinguisticTagIdiom isEqualToString:theTagWord.tag]
            )
        {
            if(![self.notKeyWords containsObject:theTagWord.getLemma])
            {
                wordColor = [UIColor greenColor];
                tempFont = [UIFont systemFontOfSize:KLargeFontSize*1.2];
            }
        }
        
        objects = [[NSArray  alloc] initWithObjects:tempFont,backgroundColor, wordColor, nil];
        keys    = [[NSArray  alloc] initWithObjects:NSFontAttributeName, NSBackgroundColorAttributeName, NSForegroundColorAttributeName,nil];
        
        NSDictionary *attrs = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
        [styleSentence  setAttributes:attrs range:theTagWord.tokenRange];
    }];
    
    return styleSentence;
}

- (void)touchtop
{
    if ([self.topTextView.index integerValue]==_gameIndex)
    {
        if (_gameIndex<self.subtitle.countOfSubItems-1)
        {
            [self.topTextView d3_flip];
            [self.bottomTextView d3_flip];
        }
        else
        {
//            [self.topTextView d3_drop];
//            [self.bottomTextView d3_drop];
        }
        
        [self nextGame];
    }
    else
    {
        [self.topTextView d3_shake];
    }
}

- (void)touchbottom
{
    if ([self.bottomTextView.index integerValue]==_gameIndex)
    {
        if (_gameIndex<self.subtitle.countOfSubItems-1)
        {
            [self.topTextView d3_flip];
            [self.bottomTextView d3_flip];
        }
        else
        {
//            [self.topTextView d3_drop];
//            [self.bottomTextView d3_drop];
        }
        
        [self nextGame];
    }
    else
    {
        [self.bottomTextView d3_shake];
    }
}

-(void) nextGame
{
    _gameIndex++;
    
    if (_gameIndex>=self.subtitle.countOfSubItems)
    {
        [self animation];
        
        [self d3_fadeOut:3 completion:^{
            
            [self.fireworksEmitter removeFromSuperlayer];
            self.fireworksEmitter = nil;
            
            iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
            [FlyingDataManager awardGold:10];
            NSString * message = NSLocalizedString(@"闯关成功，奖励金币10个", nil);
            [appDelegate makeToast:message];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(endMagicGameByPlayer:)])
            {
                [self.delegate endMagicGameByPlayer:NO];
            }
        }];
    }
    else
    {
        [self beginGameAtIndex:_gameIndex];
        
        //更新
        if (self.delegate && [self.delegate respondsToSelector:@selector(setMagicGameAt:)])
        {
            [self.delegate setMagicGameAt:self.gameIndex];
        }
    }
}

//烟花动画
- (void)animation
{
    // Cells spawn in the bottom, moving up
    
    iFlyingAppDelegate *appDelegate = (iFlyingAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Cells spawn in the bottom, moving up
    self.fireworksEmitter = [CAEmitterLayer layer];
    CGRect viewBounds = appDelegate.window.layer.bounds;
    self.fireworksEmitter.emitterPosition = \
    CGPointMake(viewBounds.size.width/2.0, viewBounds.size.height);
    
    self.fireworksEmitter.emitterSize    = CGSizeMake(viewBounds.size.width/2.0, 0.0);
    self.fireworksEmitter.emitterMode    = kCAEmitterLayerOutline;
    self.fireworksEmitter.emitterShape    = kCAEmitterLayerLine;
    self.fireworksEmitter.renderMode        = kCAEmitterLayerAdditive;
    self.fireworksEmitter.seed = (arc4random()%100)+1;
    
    // Create the rocket
    CAEmitterCell* rocket = [CAEmitterCell emitterCell];
    
    rocket.birthRate        = 1.0;
    rocket.emissionRange    = 0.25 * M_PI;  // some variation in angle
    rocket.velocity            = 380;
    rocket.velocityRange    = 100;
    rocket.yAcceleration    = 75;
    rocket.lifetime            = 1.02;    // we cannot set the birthrate < 1.0 for the burst
    
    rocket.contents            = (id) [[UIImage imageNamed:@"DazRing"] CGImage];
    rocket.scale            = 0.2;
    rocket.color            = [[UIColor redColor] CGColor];
    rocket.greenRange        = 1.0;        // different colors
    rocket.redRange            = 1.0;
    rocket.blueRange        = 1.0;
    rocket.spinRange        = M_PI;        // slow spin
    
    
    
    // the burst object cannot be seen, but will spawn the sparks
    // we change the color here, since the sparks inherit its value
    CAEmitterCell* burst = [CAEmitterCell emitterCell];
    
    burst.birthRate            = 1.0;        // at the end of travel
    burst.velocity            = 0;
    burst.scale                = 2.5;
    burst.redSpeed            =-1.5;        // shifting
    burst.blueSpeed            =+1.5;        // shifting
    burst.greenSpeed        =+1.0;        // shifting
    burst.lifetime            = 0.35;
    
    // and finally, the sparks
    CAEmitterCell* spark = [CAEmitterCell emitterCell];
    
    spark.birthRate            = 400;
    spark.velocity            = 125;
    spark.emissionRange        = 2* M_PI;    // 360 deg
    spark.yAcceleration        = 75;        // gravity
    spark.lifetime            = 3;
    
    spark.contents            = (id) [[UIImage imageNamed:@"DazRing"] CGImage];
    spark.scaleSpeed        =-0.2;
    spark.greenSpeed        =-0.1;
    spark.redSpeed            = 0.4;
    spark.blueSpeed            =-0.1;
    spark.alphaSpeed        =-0.25;
    spark.spin                = 2* M_PI;
    spark.spinRange            = 2* M_PI;
    
    // putting it together
    self.fireworksEmitter.emitterCells    = [NSArray arrayWithObject:rocket];
    rocket.emitterCells                = [NSArray arrayWithObject:burst];
    burst.emitterCells                = [NSArray arrayWithObject:spark];
    [appDelegate.window.layer addSublayer:self.fireworksEmitter];
}



@end
