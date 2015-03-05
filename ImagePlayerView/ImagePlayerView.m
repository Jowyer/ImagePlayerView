//
//  ImagePlayerView.m
//  ImagePlayerView
//
//  Created by 陈颜俊 on 14-6-5.
//  Copyright (c) 2014年 Chenyanjun. All rights reserved.
//

#import "ImagePlayerView.h"

#define kStartTag   1000
#define kDefaultScrollInterval  2

@interface ImagePlayerView() <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) NSTimer *autoScrollTimer;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) NSMutableArray *pageControlConstraints;
@property (nonatomic, strong) NSMutableArray *scrollViewConstraints;
@end

@implementation ImagePlayerView {
    BOOL isClickPageControl;
}

#pragma mark - Life Circle
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }
    return self;
}

- (id)initWithDelegate:(id<ImagePlayerViewDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.imagePlayerViewDelegate = delegate;
        [self _init];
    }
    return self;
}

- (void)_init
{
    [self addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];

    self.scrollViewConstraints = [NSMutableArray array];
    
    self.scrollInterval = kDefaultScrollInterval;
    
    // scrollview
    if (!self.scrollView) {
        self.scrollView = [[UIScrollView alloc] init];
        [self addSubview:self.scrollView];
    }
    
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.bounces = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.directionalLockEnabled = YES;
    
    self.scrollView.delegate = self;
    
    // UIPageControl
    if (!self.pageControl) {
        self.pageControl = [[UIPageControl alloc] init];
    }
    self.pageControl.userInteractionEnabled = YES;
    self.pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.pageControl.numberOfPages = self.count;
    self.pageControl.currentPage = 0;
    [self.pageControl addTarget:self action:@selector(handleClickPageControl:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.pageControl];
    
    NSArray *pageControlVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[pageControl]-0-|"
                                                                               options:kNilOptions
                                                                               metrics:nil
                                                                                 views:@{@"pageControl": self.pageControl}];
    NSArray *pageControlHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[pageControl]-|"
                                                                               options:kNilOptions
                                                                               metrics:nil
                                                                                 views:@{@"pageControl": self.pageControl}];
    self.pageControlConstraints = [NSMutableArray arrayWithArray:pageControlVConstraints];
    [self.pageControlConstraints addObjectsFromArray:pageControlHConstraints];
    [self addConstraints:self.pageControlConstraints];

    self.edgeInsets = UIEdgeInsetsZero;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"bounds"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"bounds"]) {
        [self reloadData];
    }
}

#pragma mark - Public Methods
- (void)reloadData
{
    // remove subview from scrollview first
    for (UIView *subView in self.scrollView.subviews) {
        [subView removeFromSuperview];
    }
    
    self.count = [self.imagePlayerViewDelegate numberOfItems];
    
    self.pageControl.numberOfPages = self.count;
    self.pageControl.currentPage = 0;
    
    if (self.count == 0) {
        return;
    }
    
    CGFloat width = self.bounds.size.width - self.edgeInsets.left - self.edgeInsets.right;
    CGFloat height = self.bounds.size.height - self.edgeInsets.top - self.edgeInsets.bottom;
    
    /*
     Add 2 more pages.
     The scrollview's first page is a copy of the last image.
     The scrollview's last page is a copy of the first image.
    */
    for (int i = 0; i < self.count + 2; i++) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.tag = kStartTag + i;
        imageView.userInteractionEnabled = YES;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)]];
        [self.scrollView addSubview:imageView];
        
        [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:width]];
        [imageView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:height]];
        
       
        
        if (i == 0) {
            [self.imagePlayerViewDelegate imagePlayerView:self loadImageForImageView:imageView index:self.count - 1];
        } else if (i == self.count + 2 - 1) {
            [self.imagePlayerViewDelegate imagePlayerView:self loadImageForImageView:imageView index:0];
        } else {
            [self.imagePlayerViewDelegate imagePlayerView:self loadImageForImageView:imageView index:i - 1];
        }
    }
    
    // constraint
    NSMutableDictionary *viewsDictionary = [NSMutableDictionary dictionary];
    NSMutableArray *imageViewNames = [NSMutableArray array];
    for (int i = kStartTag; i < kStartTag + self.count + 2; i++) {
        NSString *imageViewName = [NSString stringWithFormat:@"imageView%d", i - kStartTag];
        [imageViewNames addObject:imageViewName];
        
        UIImageView *imageView = (UIImageView *)[self.scrollView viewWithTag:i];
        [viewsDictionary setObject:imageView forKey:imageViewName];
    }
    
    [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-0-[%@]-0-|", [imageViewNames objectAtIndex:0]]
                                                                            options:kNilOptions
                                                                            metrics:nil
                                                                              views:viewsDictionary]];
    
    NSMutableString *hConstraintString = [NSMutableString string];
    [hConstraintString appendString:@"H:|-0"];
    for (NSString *imageViewName in imageViewNames) {
        [hConstraintString appendFormat:@"-[%@]-0", imageViewName];
    }
    [hConstraintString appendString:@"-|"];
    
    [self.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:hConstraintString
                                                                            options:NSLayoutFormatAlignAllTop
                                                                            metrics:nil
                                                                              views:viewsDictionary]];
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * (self.count + 2), self.scrollView.frame.size.height);
    self.scrollView.contentInset = UIEdgeInsetsZero;
}

- (void)adjustScrollViewContentOffset {
    UIImageView *imageView = (UIImageView *)[self.scrollView viewWithTag:(1 + kStartTag)];
    self.scrollView.contentOffset = imageView.frame.origin;
}

- (void)stopTimer
{
    if (self.autoScrollTimer && self.autoScrollTimer.isValid) {
        [self.autoScrollTimer invalidate];
        self.autoScrollTimer = nil;
    }
}

#pragma mark - actions
- (void)handleTapGesture:(UIGestureRecognizer *)tapGesture
{
    UIImageView *imageView = (UIImageView *)tapGesture.view;
    NSInteger index = imageView.tag - kStartTag;
    if (index == 0) {
        index = self.count - 1;
    } else if (index == self.count + 2 - 1) {
        index = 0;
    } else {
        index = index - 1;
    }
    
    if (self.imagePlayerViewDelegate && [self.imagePlayerViewDelegate respondsToSelector:@selector(imagePlayerView:didTapAtIndex:)]) {
        [self.imagePlayerViewDelegate imagePlayerView:self didTapAtIndex:index];
    }
}

- (void)handleClickPageControl:(UIPageControl *)sender {
    isClickPageControl = YES;
    if (self.autoScrollTimer && self.autoScrollTimer.isValid) {
        [self.autoScrollTimer invalidate];
    }
    if (self.autoScroll) {
        self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:self.scrollInterval target:self selector:@selector(handleScrollTimer:) userInfo:nil repeats:YES];
    }
    
    UIImageView *imageView = (UIImageView *)[self.scrollView viewWithTag:(sender.currentPage + kStartTag + 1)];
    [self.scrollView scrollRectToVisible:imageView.frame animated:YES];
}

#pragma mark - auto scroll
- (void)setAutoScroll:(BOOL)autoScroll
{
    _autoScroll = autoScroll;
    
    if (autoScroll) {
        if (!self.autoScrollTimer || !self.autoScrollTimer.isValid) {
            self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:self.scrollInterval target:self selector:@selector(handleScrollTimer:) userInfo:nil repeats:YES];
        }
    } else {
        if (self.autoScrollTimer && self.autoScrollTimer.isValid) {
            [self.autoScrollTimer invalidate];
            self.autoScrollTimer = nil;
        }
    }
}

- (void)setScrollInterval:(NSUInteger)scrollInterval
{
    _scrollInterval = scrollInterval;
    
    if (self.autoScrollTimer && self.autoScrollTimer.isValid) {
        [self.autoScrollTimer invalidate];
        self.autoScrollTimer = nil;
    }
    
    self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:self.scrollInterval target:self selector:@selector(handleScrollTimer:) userInfo:nil repeats:YES];
}

- (void)handleScrollTimer:(NSTimer *)timer
{
    if (self.count == 0) {
        return;
    }
    
    NSInteger currentPage = self.pageControl.currentPage;
    NSInteger nextPage = currentPage + 1;
    
    UIImageView *imageView = (UIImageView *)[self.scrollView viewWithTag:(nextPage + kStartTag + 1)];
    [self.scrollView scrollRectToVisible:imageView.frame animated:YES];
}

#pragma mark - scroll delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat offset = _scrollView.contentOffset.x;
    CGFloat pageSize = _scrollView.frame.size.width;
    
    // If present in scroll view's first page, move it to second last page
    if (offset < pageSize) {
        [_scrollView setContentOffset:CGPointMake(pageSize * self.count + offset, 0) animated:NO];
    }
    // If present in scroll view's last page, move it to second page.
    else if (offset >= pageSize * (_pageControl.numberOfPages + 1)) {
        CGFloat difference = offset - pageSize * _pageControl.numberOfPages;
        [_scrollView setContentOffset:CGPointMake(difference, 0) animated:NO];
    }
    
    if (!isClickPageControl) {
        int page = floor((offset + (pageSize/2)) / pageSize);
        if (page == 0) {
            page = (int)self.pageControl.numberOfPages - 1;
        }
        else if (page == _pageControl.numberOfPages + 1) {
            page = 0;
        }
        else {
            page = page - 1;
        }
        _pageControl.currentPage = page;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (isClickPageControl) {
        isClickPageControl = NO;
    }
    // when user scrolls manually, stop timer and start timer again to avoid next scroll immediatelly
    if (self.autoScrollTimer && self.autoScrollTimer.isValid) {
        [self.autoScrollTimer invalidate];
    }
    if (self.autoScroll) {
        self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:self.scrollInterval target:self selector:@selector(handleScrollTimer:) userInfo:nil repeats:YES];
    }
}

#pragma mark - settings
- (void)setPageControlPosition:(ICPageControlPosition)pageControlPosition
{
    NSString *vFormat = nil;
    NSString *hFormat = nil;
    
    switch (pageControlPosition) {
        case ICPageControlPosition_TopLeft: {
            vFormat = @"V:|-0-[pageControl]";
            hFormat = @"H:|-[pageControl]";
            break;
        }
            
        case ICPageControlPosition_TopCenter: {
            vFormat = @"V:|-0-[pageControl]";
            hFormat = @"H:|[pageControl]|";
            break;
        }
            
        case ICPageControlPosition_TopRight: {
            vFormat = @"V:|-0-[pageControl]";
            hFormat = @"H:[pageControl]-|";
            break;
        }
            
        case ICPageControlPosition_BottomLeft: {
            vFormat = @"V:[pageControl]-0-|";
            hFormat = @"H:|-[pageControl]";
            break;
        }
            
        case ICPageControlPosition_BottomCenter: {
            vFormat = @"V:[pageControl]-0-|";
            hFormat = @"H:|[pageControl]|";
            break;
        }
            
        case ICPageControlPosition_BottomRight: {
            vFormat = @"V:[pageControl]-0-|";
            hFormat = @"H:[pageControl]-|";
            break;
        }
            
        default:
            break;
    }
    
    [self removeConstraints:self.pageControlConstraints];
    
    NSArray *pageControlVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:vFormat
                                                                               options:kNilOptions
                                                                               metrics:nil
                                                                                 views:@{@"pageControl": self.pageControl}];
    
    NSArray *pageControlHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:hFormat
                                                                               options:kNilOptions
                                                                               metrics:nil
                                                                                 views:@{@"pageControl": self.pageControl}];
    
    [self.pageControlConstraints removeAllObjects];
    [self.pageControlConstraints addObjectsFromArray:pageControlVConstraints];
    [self.pageControlConstraints addObjectsFromArray:pageControlHConstraints];
    
    [self addConstraints:self.pageControlConstraints];
}

- (void)setHidePageControl:(BOOL)hidePageControl
{
    self.pageControl.hidden = hidePageControl;
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
{
    _edgeInsets = edgeInsets;
    
    [self removeConstraints:self.scrollViewConstraints];
    
    NSArray *scrollViewVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[scrollView]-bottom-|"
                                                                              options:kNilOptions
                                                                              metrics:@{@"top": @(self.edgeInsets.top),
                                                                                        @"bottom": @(self.edgeInsets.bottom)}
                                                                                views:@{@"scrollView": self.scrollView}];
    NSArray *scrollViewHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[scrollView]-right-|"
                                                                              options:kNilOptions
                                                                              metrics:@{@"left": @(self.edgeInsets.left),
                                                                                        @"right": @(self.edgeInsets.right)}
                                                                                views:@{@"scrollView": self.scrollView}];
    
    [self.scrollViewConstraints removeAllObjects];
    [self.scrollViewConstraints addObjectsFromArray:scrollViewHConstraints];
    [self.scrollViewConstraints addObjectsFromArray:scrollViewVConstraints];
    
    [self addConstraints:self.scrollViewConstraints];
    
    // update imageview constraints
    CGFloat width = self.bounds.size.width - self.edgeInsets.left - self.edgeInsets.right;
    CGFloat height = self.bounds.size.height - self.edgeInsets.top - self.edgeInsets.bottom;
    
    for (UIView *subView in self.scrollView.subviews) {
        if ([subView isKindOfClass:[UIImageView class]]) {
            UIImageView *imageView = (UIImageView *)subView;
            for (NSLayoutConstraint *constraint in imageView.constraints) {
                if (constraint.firstAttribute == NSLayoutAttributeWidth) {
                    constraint.constant = width;
                } else if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                    constraint.constant = height;
                }
            }
        }
    }
}

@end

