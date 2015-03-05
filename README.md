ImagePlayerView
===============

The original one is 👆there.

I made an update to support scrolling infinitely, based on Version 1.0.2, authored on 20 Nov 2014.

## Usage

You'll have to call

```objective-c
[self.imagePlayerView reloadData];
```

explicitly.

And do some adjustment work in `viewDidAppear`. 

``` objective-c
- (void)viewDidAppear:(BOOL)animated {
    [self.imagePlayerView adjustScrollViewContentOffset];
    [super viewDidAppear:YES];
}
```