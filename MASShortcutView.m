#import "MASShortcutView.h"
#import "MASShortcut.h"

#define HINT_BUTTON_WIDTH 23.0
#define BUTTON_FONT_SIZE 13.0
#define SEGMENT_CHROME_WIDTH 6.0

#pragma mark -

@interface MASShortcutView () // Private accessors

@property (nonatomic, getter = isHinting) BOOL hinting;
@property (nonatomic, copy) NSString *shortcutPlaceholder;
@property (nonatomic, strong) NSTextField *shortcutLabel;
@property (nonatomic, strong) NSImage *clearFieldImage;

@end

#pragma mark -

@implementation MASShortcutView {
    NSButtonCell *_shortcutCell;
    NSInteger _shortcutToolTipTag;
    NSInteger _hintToolTipTag;
    NSTrackingArea *_hintArea;
}

@synthesize enabled = _enabled;
@synthesize hinting = _hinting;
@synthesize shortcutValue = _shortcutValue;
@synthesize shortcutPlaceholder = _shortcutPlaceholder;
@synthesize shortcutValueChange = _shortcutValueChange;
@synthesize recording = _recording;
@synthesize appearance = _appearance;

#pragma mark -

- (id)initWithFrame:(CGRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {

      self.clearFieldImage = [NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate];

      self.shortcutLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, frameRect.size.width, frameRect.size.height)];
      [self.shortcutLabel setBezeled:NO];
      [self.shortcutLabel setDrawsBackground:NO];
      [self.shortcutLabel setEditable:NO];
      [self.shortcutLabel setSelectable:NO];
      [self addSubview:self.shortcutLabel];

      _shortcutCell = [[NSButtonCell alloc] init];
      //_shortcutCell.buttonType = NSPushOnPushOffButton;
      //_shortcutCell.font = [[NSFontManager sharedFontManager] convertFont:_shortcutCell.font toSize:BUTTON_FONT_SIZE];
      _enabled = YES;
      [self resetShortcutCellStyle];
    }
    return self;
}

- (void)dealloc
{
    [self activateEventMonitoring:NO];
    [self activateResignObserver:NO];
}

#pragma mark - Public accessors

- (void)setEnabled:(BOOL)flag
{
    if (_enabled != flag) {
        _enabled = flag;
        [self updateTrackingAreas];
        self.recording = NO;
        [self setNeedsDisplay:YES];
    }
}

- (void)setAppearance:(MASShortcutViewAppearance)appearance
{
    if (_appearance != appearance) {
        _appearance = appearance;
        [self resetShortcutCellStyle];
        [self setNeedsDisplay:YES];
    }
}

- (void)resetShortcutCellStyle
{
//    switch (_appearance) {
//        case MASShortcutViewAppearanceDefault: {
//            _shortcutCell.bezelStyle = NSRoundedBezelStyle;
//            break;
//        }
//        case MASShortcutViewAppearanceTexturedRect: {
//            _shortcutCell.bezelStyle = NSTexturedRoundedBezelStyle;
//            break;
//        }
//        case MASShortcutViewAppearanceRounded: {
//            _shortcutCell.bezelStyle = NSRoundedBezelStyle;
//            break;
//        }
//    }
}

- (void)setRecording:(BOOL)flag
{
    // Only one recorder can be active at the moment
    static MASShortcutView *currentRecorder = nil;
    if (flag && (currentRecorder != self)) {
        currentRecorder.recording = NO;
        currentRecorder = flag ? self : nil;
    }
    
    // Only enabled view supports recording
    if (flag && !self.enabled) return;
    
    if (_recording != flag) {
        _recording = flag;
        self.shortcutPlaceholder = nil;
        [self resetToolTips];
        [self activateEventMonitoring:_recording];
        [self activateResignObserver:_recording];
        [self setNeedsDisplay:YES];
    }
}

- (void)setShortcutValue:(MASShortcut *)shortcutValue
{
    _shortcutValue = shortcutValue;
    [self resetToolTips];
    [self setNeedsDisplay:YES];

    if (self.shortcutValueChange) {
        self.shortcutValueChange(self);
    }
}

- (void)setShortcutPlaceholder:(NSString *)shortcutPlaceholder
{
    _shortcutPlaceholder = shortcutPlaceholder.copy;
    [self setNeedsDisplay:YES];
}

#pragma mark - Drawing

- (BOOL)isFlipped {
    return YES;
}


#pragma mark - messing around
- (void)verticalCenterLabel {
  // NSTextField doesn't vertically center its contents, so we position it manually
  CGSize sz = [@"Record shortcut" sizeWithAttributes:
               [NSDictionary dictionaryWithObject: [NSFont fontWithName: self.shortcutLabel.font.familyName
                                                                   size: self.shortcutLabel.font.pointSize]
                                           forKey: NSFontAttributeName]];
  NSPoint origin = self.shortcutLabel.frame.origin;
  origin.y = (self.frame.size.height - sz.height) / 2;
  [self.shortcutLabel setFrameOrigin:origin];
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (BOOL)wantsLayer {
  return NO;
}

- (BOOL)showsFirstResponder {
  return YES;
}

- (BOOL)becomeFirstResponder {
  [self drawFocusRingMask];
  return YES;
}

- (NSBezierPath *)controlShape
{
  NSRect shapeBounds = self.bounds;
  // Stroke will be 1 px, so align shape to pixel centers
  shapeBounds = NSInsetRect(shapeBounds, 0.5, 0.5);
  return [NSBezierPath bezierPathWithRoundedRect:shapeBounds
                                         xRadius:self.bounds.size.height/2
                                         yRadius:self.bounds.size.height/2];
}

- (void)drawFocusRingMask
{
  if (self.window.firstResponder == self)
    [self.controlShape fill];
}

- (NSRect)focusRingMaskBounds
{
  if (self.window.firstResponder == self)
    return self.controlShape.bounds;
  else
    return NSZeroRect;
}

#pragma mark -

- (void)drawInRect:(CGRect)frame withTitle:(NSString *)title alignment:(NSTextAlignment)alignment state:(NSInteger)state
{
  [self.shortcutLabel setStringValue:title];
  
  self.shortcutLabel.alignment = alignment;

//  [self.shortcutLabel setNeedsDisplay:YES];

//    _shortcutCell.title = title;
//    _shortcutCell.alignment = alignment;
//    _shortcutCell.state = state;
//    _shortcutCell.enabled = self.enabled;
//
//    switch (_appearance) {
//        case MASShortcutViewAppearanceDefault: {
//            [_shortcutCell drawWithFrame:frame inView:self];
//            break;
//        }
//        case MASShortcutViewAppearanceTexturedRect: {
//            [_shortcutCell drawWithFrame:CGRectOffset(frame, 0.0, 1.0) inView:self];
//            break;
//        }
//        case MASShortcutViewAppearanceRounded: {
//            [_shortcutCell drawWithFrame:CGRectOffset(frame, 0.0, 1.0) inView:self];
//            break;
//        }
//    }
}

- (void)drawRect:(CGRect)dirtyRect
{
  [[NSColor whiteColor] setFill];
  [[NSColor lightGrayColor] setStroke];
  
  [[self controlShape] setLineWidth:0.5];
  [[self controlShape] fill];
  [[self controlShape] stroke];

  // Show clear button if recording or defined
  float inset = 4;
  float clearSize = self.shortcutLabel.frame.size.height - inset * 2;
  if (self.shortcutValue || self.recording) {
    CGRect clearRect = CGRectMake(self.shortcutLabel.frame.size.width - (inset + clearSize),
                                  inset,
                                  clearSize,
                                  clearSize);
    [self.clearFieldImage drawInRect:clearRect
                            fromRect:NSZeroRect
                           operation:NSCompositeSourceOver
                            fraction:0.28];
  }

  // Gray when shortcut is recording or undefined
  if (!self.shortcutValue || self.recording) {
    [self.shortcutLabel setFont:[NSFont systemFontOfSize:10]];
    [self.shortcutLabel setTextColor:[NSColor disabledControlTextColor]];
  } else {
    [self.shortcutLabel setFont:[NSFont systemFontOfSize:11]];
    [self.shortcutLabel setTextColor:[NSColor textColor]];
  }
  NSString *title;
  [self verticalCenterLabel];
    if (self.shortcutValue) {
        [self drawInRect:self.bounds withTitle:MASShortcutChar(self.recording ? kMASShortcutGlyphEscape : kMASShortcutGlyphDeleteLeft)
               alignment:NSRightTextAlignment state:NSOffState];
        
        CGRect shortcutRect;
        [self getShortcutRect:&shortcutRect hintRect:NULL];
        title = (self.recording
                           ? (_hinting
                              ? NSLocalizedString(@"Use Old Shortcut", @"Cancel action button for non-empty shortcut in recording state")
                              : (self.shortcutPlaceholder.length > 0
                                 ? self.shortcutPlaceholder
                                 : NSLocalizedString(@"Type New Shortcut", @"Non-empty shortcut button in recording state")))
                           : _shortcutValue ? _shortcutValue.description : @"");
        [self drawInRect:shortcutRect withTitle:title alignment:NSCenterTextAlignment state:self.isRecording ? NSOnState : NSOffState];
    }
    else {
        if (self.recording)
        {
            [self drawInRect:self.bounds withTitle:MASShortcutChar(kMASShortcutGlyphEscape) alignment:NSRightTextAlignment state:NSOffState];

            CGRect shortcutRect;
            [self getShortcutRect:&shortcutRect hintRect:NULL];
            title = (_hinting
                               ? NSLocalizedString(@"Cancel", @"Cancel action button in recording state")
                               : (self.shortcutPlaceholder.length > 0
                                  ? self.shortcutPlaceholder
                                  : NSLocalizedString(@"Type shortcut", @"Empty shortcut button in recording state")));
            [self drawInRect:shortcutRect withTitle:title alignment:NSCenterTextAlignment state:NSOnState];
        }
        else
        {
            title = NSLocalizedString(@"Click to record shortcut", @"Empty shortcut button in normal state");
            [self drawInRect:self.bounds withTitle:title
                   alignment:NSCenterTextAlignment state:NSOffState];
        }
    }
}

#pragma mark - Mouse handling

- (void)getShortcutRect:(CGRect *)shortcutRectRef hintRect:(CGRect *)hintRectRef
{
    CGRect shortcutRect, hintRect;
    CGFloat hintButtonWidth = HINT_BUTTON_WIDTH;
    switch (self.appearance) {
        case MASShortcutViewAppearanceTexturedRect: hintButtonWidth += 2.0; break;
        case MASShortcutViewAppearanceRounded: hintButtonWidth += 3.0; break;
        default: break;
    }
    CGRectDivide(self.bounds, &hintRect, &shortcutRect, hintButtonWidth, CGRectMaxXEdge);
    if (shortcutRectRef)  *shortcutRectRef = shortcutRect;
    if (hintRectRef) *hintRectRef = hintRect;
}

- (BOOL)locationInShortcutRect:(CGPoint)location
{
    CGRect shortcutRect;
    [self getShortcutRect:&shortcutRect hintRect:NULL];
    return CGRectContainsPoint(shortcutRect, [self convertPoint:location fromView:nil]);
}

- (BOOL)locationInHintRect:(CGPoint)location
{
    CGRect hintRect;
    [self getShortcutRect:NULL hintRect:&hintRect];
    return CGRectContainsPoint(hintRect, [self convertPoint:location fromView:nil]);
}

- (void)mouseDown:(NSEvent *)event
{
  [[self window] makeFirstResponder:self];
    if (self.enabled) {
        if (self.shortcutValue) {
            if (self.recording) {
                if ([self locationInHintRect:event.locationInWindow]) {
                    self.recording = NO;
                }
            }
            else {
                if ([self locationInShortcutRect:event.locationInWindow]) {
                    self.recording = YES;
                }
                else {
                    self.shortcutValue = nil;
                }
            }
        }
        else {
            if (self.recording) {
                if ([self locationInHintRect:event.locationInWindow]) {
                    self.recording = NO;
                }
            }
            else {
                self.recording = YES;
            }
        }
    }
    else {
        [super mouseDown:event];
    }
}

#pragma mark - Handling mouse over

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    if (_hintArea) {
        [self removeTrackingArea:_hintArea];
        _hintArea = nil;
    }
    
    // Forbid hinting if view is disabled
    if (!self.enabled) return;
    
    CGRect hintRect;
    [self getShortcutRect:NULL hintRect:&hintRect];
    NSTrackingAreaOptions options = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingAssumeInside);
    _hintArea = [[NSTrackingArea alloc] initWithRect:hintRect options:options owner:self userInfo:nil];
    [self addTrackingArea:_hintArea];
}

- (void)setHinting:(BOOL)flag
{
    if (_hinting != flag) {
        _hinting = flag;
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseEntered:(NSEvent *)event
{
    self.hinting = YES;
}

- (void)mouseExited:(NSEvent *)event
{
    self.hinting = NO;
}

void *kUserDataShortcut = &kUserDataShortcut;
void *kUserDataHint = &kUserDataHint;

- (void)resetToolTips
{
    if (_shortcutToolTipTag) {
        [self removeToolTip:_shortcutToolTipTag], _shortcutToolTipTag = 0;
    }
    if (_hintToolTipTag) {
        [self removeToolTip:_hintToolTipTag], _hintToolTipTag = 0;
    }
    
    if ((self.shortcutValue == nil) || self.recording || !self.enabled) return;

    CGRect shortcutRect, hintRect;
    [self getShortcutRect:&shortcutRect hintRect:&hintRect];
    _shortcutToolTipTag = [self addToolTipRect:shortcutRect owner:self userData:kUserDataShortcut];
    _hintToolTipTag = [self addToolTipRect:hintRect owner:self userData:kUserDataHint];
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(CGPoint)point userData:(void *)data
{
    if (data == kUserDataShortcut) {
        return NSLocalizedString(@"Click to record new shortcut", @"Tooltip for non-empty shortcut button");
    }
    else if (data == kUserDataHint) {
        return NSLocalizedString(@"Delete shortcut", @"Tooltip for hint button near the non-empty shortcut");
    }
    return nil;
}

#pragma mark - Event monitoring

- (void)activateEventMonitoring:(BOOL)shouldActivate
{
    static BOOL isActive = NO;
    if (isActive == shouldActivate) return;
    isActive = shouldActivate;
    
    static id eventMonitor = nil;
    if (shouldActivate) {
        __weak MASShortcutView *weakSelf = self;
        NSEventMask eventMask = (NSKeyDownMask | NSFlagsChangedMask);
        eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:eventMask handler:^(NSEvent *event) {

            MASShortcut *shortcut = [MASShortcut shortcutWithEvent:event];
            if ((shortcut.keyCode == kVK_Delete) || (shortcut.keyCode == kVK_ForwardDelete)) {
                // Delete shortcut
                weakSelf.shortcutValue = nil;
                weakSelf.recording = NO;
                event = nil;
            }
            else if (shortcut.keyCode == kVK_Escape) {
                // Cancel recording
                weakSelf.recording = NO;
                event = nil;
            }
            else if (shortcut.shouldBypass) {
                // Command + W, Command + Q, ESC should deactivate recorder
                weakSelf.recording = NO;
            }
            else {
                // Verify possible shortcut
                if (shortcut.keyCodeString.length > 0) {
                    if (shortcut.valid) {
                        // Verify that shortcut is not used
                        NSError *error = nil;
                        if ([shortcut isTakenError:&error]) {
                            // Prevent cancel of recording when Alert window is key
                            [weakSelf activateResignObserver:NO];
                            [weakSelf activateEventMonitoring:NO];
                            NSString *format = NSLocalizedString(@"The key combination %@ cannot be used",
                                                                 @"Title for alert when shortcut is already used");
                            NSRunCriticalAlertPanel([NSString stringWithFormat:format, shortcut], error.localizedDescription,
                                                    NSLocalizedString(@"OK", @"Alert button when shortcut is already used"),
                                                    nil, nil);
                            weakSelf.shortcutPlaceholder = nil;
                            [weakSelf activateResignObserver:YES];
                            [weakSelf activateEventMonitoring:YES];
                        }
                        else {
                            weakSelf.shortcutValue = shortcut;
                            weakSelf.recording = NO;
                        }
                    }
                    else {
                        // Key press with or without SHIFT is not valid input
                        NSBeep();
                    }
                }
                else {
                    // User is playing with modifier keys
                    weakSelf.shortcutPlaceholder = shortcut.modifierFlagsString;
                }
                event = nil;
            }
            return event;
        }];
    }
    else {
        [NSEvent removeMonitor:eventMonitor];
    }
}

- (void)activateResignObserver:(BOOL)shouldActivate
{
    static BOOL isActive = NO;
    if (isActive == shouldActivate) return;
    isActive = shouldActivate;
    
    static id observer = nil;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    if (shouldActivate) {
        __weak MASShortcutView *weakSelf = self;
        observer = [notificationCenter addObserverForName:NSWindowDidResignKeyNotification object:self.window
                                                queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
                                                    weakSelf.recording = NO;
                                                }];
    }
    else {
        [notificationCenter removeObserver:observer];
    }
}

@end
