/*
 *    TrayIconController.h
 *
 *    Copyright (c) 2007-2011
 *
 *    Author: Andreas Schik <andreas@schik.de>
 *
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software
 *    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef __TRAYICONCONTROLLER_H_INCLUDED
#define __TRAYICONCONTROLLER_H_INCLUDED

#include <X11/Xlib.h>
#include <AppKit/AppKit.h>


@interface TrayIconController: NSObject
{
    @private
    /** The system tray window */
    Window systrayWindow;

    /** The tray icon window */
    NSWindow *trayIconWindow;
    
    NSView *contentView;

    /** The ID of the currently displayed message */
    unsigned long messageId;
   
    /** If set to YES the tray icon is pending creation, otherwise
      the icon is already created. */
    BOOL mustCreateTrayIcon;
  
    /** The text for the tooltip to be displayed when the mouse
      hovers over the tray icon. */
    NSString *tooltipText;

    /** The name of the icon to be displayed. We store this
      to be able to update the icon on theme changes. */
    NSString *currentIcon;

    /** This is the default path to look for icons. */
    NSString *defaultIconPath;
}

- (id) init;

- (void) createImage: (NSString *) iconName;

- (void) createButton: (NSString *) iconName
               target: (id) target
               action: (SEL) action;

- (unsigned long) sendMessage: (NSString *) message
                      timeout: (long) timeout;

- (void) cancelMessage: (unsigned long) mid;
 
- (void) showTrayIcon;

- (void) hideTrayIcon;

- (void) setTooltipText: (NSString *) text;

- (void) setIcon: (NSString *) iconName;

- (void) setTooltipText: (NSString *) text;

- (void) setDefaultIconPath: (NSString *) path;

@end

#endif
