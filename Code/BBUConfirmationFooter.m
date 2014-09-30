//
//  BBUConfirmationFooter.m
//  image-uploader
//
//  Created by Boris Bügling on 29/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUAppStyle.h"
#import "BBUConfirmationFooter.h"
#import "NSView+Geometry.h"

@implementation BBUConfirmationFooter

@synthesize confirmationButton = _confirmationButton;
@synthesize informationLabel = _informationLabel;

#pragma mark -

-(NSButton *)confirmationButton {
    if (!_confirmationButton) {
        _confirmationButton = [[NSButton alloc] initWithFrame:NSMakeRect(20.0, 0.0, 100.0, 40.0)];
        _confirmationButton.alignment = NSLeftTextAlignment;
        _confirmationButton.bordered = NO;
        _confirmationButton.font = [BBUAppStyle defaultStyle].titleFont;
        [_confirmationButton.cell setBackgroundColor:[BBUAppStyle defaultStyle].primaryButtonColor];
        [self addSubview:_confirmationButton];
    }

    return _confirmationButton;
}

-(void)drawRect:(NSRect)dirtyRect {
    self.confirmationButton.y = self.height - 20.0 - self.confirmationButton.height;

    self.informationLabel.width = self.width - 40.0;

    [super drawRect:dirtyRect];
}

-(NSTextField *)informationLabel {
    if (!_informationLabel) {
        _informationLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20.0, 20.0, 0.0, 70.0)];
        _informationLabel.backgroundColor = [BBUAppStyle defaultStyle].informationColor;
        _informationLabel.bordered = NO;
        _informationLabel.editable = NO;
        _informationLabel.font = [BBUAppStyle defaultStyle].subtitleFont;
        _informationLabel.textColor = [NSColor blackColor];
        [self addSubview:_informationLabel];
    }

    return _informationLabel;
}

@end
