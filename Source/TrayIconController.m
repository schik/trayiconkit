/*
 *  TrayIconController.m
 *
 *  Copyright (c) 2007-2011
 *
 *  Author: Andreas Schik <andreas@schik.de>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSDisplayServer.h>

#import "TrayIconKit/TrayIconController.h"


#define SYSTEM_TRAY_REQUEST_DOCK  0
#define SYSTEM_TRAY_BEGIN_MESSAGE   1
#define SYSTEM_TRAY_CANCEL_MESSAGE  2


static Display *display = NULL;
GSDisplayServer *server = NULL;
Window root = None;
Atom atomSystemTrayS;
Atom atomSystrayOpcode;
Atom atomManager;

// Stop the compiler from complaining
@interface GSDisplayServer (TrayIconPrivate)
 - (void) processEvent: (XEvent *) event;
@end

@interface TrayIconController (Private)

- (void) setupX11;

- (void) teardownX11;

- (void) selectSystemTray;

- (void) sendDockRequest;

- (void) createTrayIcon;

- (void) destroyTrayIcon;

- (void) sendManagerMessage: (long) message
                     window: (Window) xwindow
                      data1: (long) data1
                      data2: (long) data2
                      data3: (long) data3;

- (NSView *) setupImageContentView: (NSImage *) image
                           forSize: (NSSize) size;

- (NSView *) setupButtonContentView: (NSImage *) image
                            forSize: (NSSize) size
                             target: (id) target
                             action: (SEL) action;

- (BOOL) handleXEvent: (XEvent) event;

- (NSImage *) getIcon: (NSString *) iconName;

@end

@implementation TrayIconController (Private)

- (void) setupX11
{
  // Get the display and root window
  display = (Display *)[GSCurrentServer() serverDevice];
  int screen = [[NSScreen mainScreen] screenNumber];
  root = RootWindow(display, screen);

  // Get a couple of atoms
  NSString *name = [NSString stringWithFormat: @"_NET_SYSTEM_TRAY_S%d", screen];
  atomSystemTrayS = XInternAtom(display, [name cString], False);
  atomManager = XInternAtom(display, "MANAGER", False);
  atomSystrayOpcode = XInternAtom (display, "_NET_SYSTEM_TRAY_OPCODE", False);

  // Listen for X events on the root window
  XSelectInput(display, root, StructureNotifyMask);

  NSRunLoop *loop = [NSRunLoop currentRunLoop];
  int xEventQueueFd = XConnectionNumber(display);

  [loop addEvent: (void*)(gsaddr)xEventQueueFd
            type: ET_RDESC
         watcher: (id<RunLoopEvents>)self
         forMode: NSConnectionReplyMode];

  [loop addEvent: (void*)(gsaddr)xEventQueueFd
            type: ET_RDESC
         watcher: (id<RunLoopEvents>)self
         forMode: NSDefaultRunLoopMode];
}

- (void) teardownX11
{
  XSelectInput(display, root, NoEventMask);
  if (trayIconWindow != nil) {
    XSelectInput(display, (Window)[trayIconWindow windowRef], NoEventMask);
  }

  NSRunLoop *loop = [NSRunLoop currentRunLoop];
  int xEventQueueFd = XConnectionNumber(display);

  [loop removeEvent: (void*)(gsaddr)xEventQueueFd
               type: ET_RDESC
            forMode: NSConnectionReplyMode
                all: YES];

  [loop removeEvent: (void*)(gsaddr)xEventQueueFd
               type: ET_RDESC
            forMode: NSDefaultRunLoopMode
                all: YES];
}

- (void) selectSystemTray
{
  systrayWindow = XGetSelectionOwner(display, atomSystemTrayS);

  if (systrayWindow != None) {
    NSDebugLog(@"Selected tray window 0x%lx", systrayWindow);
    XSelectInput(display, systrayWindow, StructureNotifyMask);
    // Check whether we have a deferred request for a tray icon
    if (mustCreateTrayIcon == YES) {
      [self createTrayIcon];
    }
  } else {
    [self destroyTrayIcon];
  }

  [self sendDockRequest];
}

- (void) sendDockRequest
{
  if (systrayWindow == None) {
    return;
  }
  if (nil == trayIconWindow) {
    return;
  }
  [self sendManagerMessage: SYSTEM_TRAY_REQUEST_DOCK
                    window: systrayWindow
                     data1: (Window)[trayIconWindow windowRef]
                     data2: 0
                     data3: 0];
}
 
- (void) createTrayIcon
{
  if (nil != trayIconWindow) {
    return;
  }
  NSRect rect = NSZeroRect;
  // Create the icon window out of the visible screen
  rect.origin.x = -40;
  rect.origin.y = -40;
  rect.size.height = 20;
  rect.size.width = 20;
  trayIconWindow = [[NSWindow alloc] initWithContentRect: rect
                          styleMask: NSBorderlessWindowMask
                            backing: NSBackingStoreRetained
                              defer: NO];
  NSColor *col = [NSColor colorWithCalibratedRed: 1.0
                       green: 1.0
                        blue: 1.0
                       alpha: 1.0];
  [trayIconWindow setBackgroundColor: col];
  [trayIconWindow setDelegate: self];
  [trayIconWindow setLevel: NSStatusWindowLevel];
  [trayIconWindow setContentView: contentView];

  if ((tooltipText != nil)  && ([tooltipText length] != 0)) {
    [[trayIconWindow contentView] setToolTip: tooltipText];
  }

  // Listen to X property changes on our own
  // tray icon window, in addition to the events listened for by -back.
  XWindowAttributes wattr;
  XGetWindowAttributes(display, (Window)[trayIconWindow windowRef], &wattr);
  XSelectInput(display, (Window)[trayIconWindow windowRef],
    wattr.your_event_mask | StructureNotifyMask | PropertyChangeMask);

  [self sendDockRequest];
}

- (void) destroyTrayIcon
{
  if (trayIconWindow != nil) {
    XSelectInput(display, (Window)[trayIconWindow windowRef], NoEventMask);
    [trayIconWindow close];
    trayIconWindow = nil;
  }
}

- (void) receivedEvent: (void *) data
                  type: (RunLoopEventType) type
                 extra: (void *) extra
               forMode: (NSString *) mode
{
  XEvent event;

  while (XPending(display)) {
    XNextEvent(display, &event);
    BOOL handled = [self handleXEvent: event];
    if (handled == NO) {
      [GSCurrentServer() processEvent: &event];
    }
  }
}

- (void) sendManagerMessage: (long)message
                     window: (Window)xwindow
                      data1: (long)data1
                      data2: (long)data2
                      data3: (long)data3
{
  XClientMessageEvent ev;

  ev.type = ClientMessage;
  ev.window = xwindow;
  ev.message_type = atomSystrayOpcode;
  ev.format = 32;
  ev.data.l[0] = CurrentTime;
  ev.data.l[1] = message;
  ev.data.l[2] = data1;
  ev.data.l[3] = data2;
  ev.data.l[4] = data3;

  XSendEvent (display, systrayWindow, False, NoEventMask, (XEvent *)&ev);
  XSync (display, False);
}

- (NSView *) setupImageContentView: (NSImage *) image
                           forSize: (NSSize)size
{
  NSRect rect = NSZeroRect;
  rect.size = size;
  NSImageView *view = [[NSImageView alloc] initWithFrame: rect];
  if (nil != image) {
    [view setImage: image];
  }
  return view;
}

- (NSView *) setupButtonContentView: (NSImage *) image
                            forSize: (NSSize) size
                             target: (id) target
                             action: (SEL) action
{
  NSRect rect = NSZeroRect;
  rect.size = size;
  NSButton *view = [[NSButton alloc] initWithFrame: rect];
  [view setImagePosition: NSImageOnly];
  [view setBordered: NO];
  [view setTarget: target];
  [view setAction: action];
  [view setButtonType: NSMomentaryChangeButton];
  if (nil != image) {
    [view setImage: image];
  }
  return view;
}

- (BOOL) handleXEvent: (XEvent) event
{
  BOOL handled = NO;
  switch (event.type) {
  case DestroyNotify:
    if (event.xany.window == systrayWindow) {
      NSDebugLog(@"The system tray was destroyed");
      // If our tray window was destroyed, we try to select
      // another one.
      [self selectSystemTray];
      handled = YES;
    }
    break;
  case ClientMessage:
    if ((event.xclient.message_type == atomManager)
         && (event.xclient.data.l[1] == atomSystemTrayS)) {
      NSDebugLog(@"A system tray came up");
      // A system tray came up. select it.
      [self selectSystemTray];
      handled = YES;
    }
    break;
  }
  return handled;
}

- (NSImage *) getIcon: (NSString *) iconName
{
  NSString *path = nil;
  NSImage *img = nil;

  // If we are supposed to load an icon from an absolute path do so.
  // Otherwise, we check whether we find the icon in the defaut path.
  if ([iconName isAbsolutePath]) {
    NSDebugLog(@"Loading icon from %@", iconName);
    path = iconName;
  }

  if ((nil == path) && (nil != defaultIconPath)) {
    path = [NSString stringWithFormat: @"%@/%@",
                            defaultIconPath, iconName];
    NSDebugLog(@"Loading icon from %@", path);
  }

  if (nil != path) {
    // If no file extension is given, we use tiff.
    NSString *ext = [path pathExtension];
    if ([@"" isEqualToString: ext]) {
      path = [path stringByAppendingPathExtension: @"tiff"];
    }
    img = [[NSImage alloc] initWithContentsOfFile: path];
    if (nil != img) {
      NSColor *col = [NSColor colorWithCalibratedRed: 1.0
                                green: 1.0
                                 blue: 1.0
                                alpha: 0.0];
      [img setBackgroundColor: col];
    }
  }
  return AUTORELEASE(img);
}

@end // Private

@implementation TrayIconController

/**
 * <p><init /></p>
 */
- (id) init
{
  self = [super init];
  if (self != nil) {
    currentIcon = nil;
    defaultIconPath = nil;
    trayIconWindow = nil;
    mustCreateTrayIcon = NO;
    messageId = 0;
    [self setupX11];
    [self selectSystemTray];
  }
  return self;
}

- (void) createImage: (NSString *) iconName
{
  NSSize size = NSMakeSize(20, 20);
  NSImage *icon = [self getIcon: iconName];
  contentView = [self setupImageContentView: icon forSize: size];
  ASSIGN(currentIcon, iconName);
}

- (void) createButton: (NSString *) iconName
               target: (id) target
               action: (SEL) action
{
  NSSize size = NSMakeSize(20, 20);
  NSImage *icon = [self getIcon: iconName];
  contentView = [self setupButtonContentView: icon
                                     forSize: size
                                      target: target
                                      action: action];
  ASSIGN(currentIcon, iconName);
}

- (void) dealloc
{
  DESTROY(currentIcon);
  DESTROY(defaultIconPath);
  DESTROY(trayIconWindow);
  DESTROY(contentView);
  DESTROY(tooltipText);
  [self teardownX11];
  [super dealloc];
}

- (void) windowDidMove: (NSNotification *) notification
{
  [trayIconWindow orderFront: self];
  [trayIconWindow display];
}

- (void) showTrayIcon
{
  if (systrayWindow == None) {
    mustCreateTrayIcon = YES;
  } else {
    [self createTrayIcon];
  }
}

- (void) hideTrayIcon
{
  mustCreateTrayIcon = NO;
  [self destroyTrayIcon];
}

- (void) setIcon: (NSString *) iconName
{
  NSView *view = [trayIconWindow contentView];
  if ((nil != view) && [view respondsToSelector: @selector(setImage:)]) {
    NSImage *icon = [self getIcon: iconName];
    [view setImage: icon];
    [view setNeedsDisplay: YES];
    ASSIGN(currentIcon, iconName);
  }
}

- (void) setTooltipText: (NSString *) text
{
  ASSIGN(tooltipText, text);
  if (trayIconWindow != nil) {
    [[trayIconWindow contentView] setToolTip: tooltipText];
  }
}

- (void) setDefaultIconPath: (NSString *) path
{
  ASSIGN(defaultIconPath, path);
}

- (unsigned long) sendMessage: (NSString *) message
                      timeout: (long) timeout
{
  if (systrayWindow == None) {
    return 0;
  }
  messageId++;

  RETAIN(message);
  int length = [message length];
  const char *cmessage = [message cString];

  [self sendManagerMessage: SYSTEM_TRAY_BEGIN_MESSAGE
                    window: (Window)[trayIconWindow windowRef]
                     data1: timeout
                     data2: length
                     data3: messageId];
  while (length) {
    XClientMessageEvent ev;
    
    ev.type = ClientMessage;
    ev.window = (Window)[trayIconWindow windowRef];
    ev.format = 8;
    ev.message_type = XInternAtom(display,
      "_NET_SYSTEM_TRAY_MESSAGE_DATA", False);
    if (length > 20) {
      memcpy (&ev.data, cmessage, 20);
      length -= 20;
      cmessage += 20;
    } else {
      memcpy (&ev.data, cmessage, length);
      length = 0;
    }

    XSendEvent(display, systrayWindow, False, StructureNotifyMask, (XEvent *)&ev);
    XSync(display, False);
  }
  RELEASE(message);
  return messageId;
}

- (void) cancelMessage: (unsigned long) mid
{
  [self sendManagerMessage: SYSTEM_TRAY_CANCEL_MESSAGE
                    window: (Window)[trayIconWindow windowRef]
                     data1: mid
                     data2: 0
                     data3: 0];
}

@end
