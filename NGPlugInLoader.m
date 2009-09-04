/*
 * Copyright (c) 2009 Mo McRoberts.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 3. The names of the author(s) of this software may not be used to endorse
 * or promote products derived from this software without specific prior
 * written permission.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * AUTHORS OF THIS SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#import "NGPlugInLoader.h"

/* Plug-in directories are split into several (ordered) groups:
 *
 * 1. Explicitly-specified bundle-relative paths
 * 2. The main bundle path
 * 3. Per-domain paths
 * 4. Any other explicit paths
 *
 * By default:
 * - the bundle-relative ("local") paths are empty.
 * - the main bundle path is initialised to [[NSBundle mainBundle] builtInPlugInsPath]
 * - per-domain paths are _lazily_ initialised to Library/Application Support/{appliationName}
 * - Other ("extra") paths are empty.
 * - applicationName is initialised to the CFBundleName key from the main
 *   bundle's Info.plist.
 *
 * The lazy initialisation of the per-domain paths means that if no call to
 * searchPath, loadPlugIns, or one of the addPath:withinDirectory:... methods is
 * setApplicationName: can be called to set the path, relative to NSApplicationSupportDirectory,
 * which -will- be used when one of these methods is invoked.
 *
 * If one of these methods has been invoked, resetDomainPaths may be called
 * to reset the per-domain path list to defaults. Note that calling
 * resetDomainPaths will (perhaps obviously) remove any paths which have
 * been added to the list.
 */

NSString *const NGPlugInLoaderPlugInDidLoadNotification = @"com.nexgenta.NGPlugInLoader.notifications.PlugInDidLoad";

@interface NGPlugInLoader(NGPlugInLoaderInternalMethods)
- (NSString *)nameOfBundle:(NSBundle *)bundle useOnlyCFBundleName:(BOOL)flag;
- (unsigned int)loadPlugInsAtPath:(NSString *)folderPath;
- (BOOL)attemptToLoadPlugInAtPath:(NSString *)bundlePath;
- (BOOL)plugInShouldLoad:(NSBundle *)bundle;
- (void)plugInDidLoad:(NSBundle *)bundle;
- (BOOL)initialisePerDomainPaths;
@end

@implementation NGPlugInLoader

+ (id)plugInLoader
{
	return [[[NGPlugInLoader alloc] init] autorelease];
}

+ (id)plugInLoaderWithExtension:(NSString *)extension
{
	return [[[NGPlugInLoader alloc] initWithExtension:extension] autorelease];
}

- (id)init
{
	return [self initWithExtension:@"bundle"];
}

- (id)initWithExtension:(NSString *)extension
{
	if((self = [super init]))
	{
		bundleExtension = [extension retain];
		localPaths = [[NSMutableArray alloc] init];
		perDomainPaths = nil;
		extraPaths = [[NSMutableArray alloc] init];
		applicationName = [self nameOfBundle:[NSBundle mainBundle] useOnlyCFBundleName:YES];
		mainBundlePlugInsPath = [[[NSBundle mainBundle] builtInPlugInsPath] retain];
	}
	return self;
}

- (void) release
{
	[bundleExtension release];
	bundleExtension = nil;
	[applicationName release];
	applicationName = nil;
	[localPaths release];
	localPaths = nil;
	[perDomainPaths release];
	perDomainPaths = nil;
	[extraPaths release];
	extraPaths = nil;
	[mainBundlePlugInsPath release];
	mainBundlePlugInsPath = nil;
	[super release];
}

- (NSArray *)searchPath
{
	NSMutableArray *array;
	
	array = [NSMutableArray array];
	if(localPaths)
	{
		[array addObjectsFromArray:localPaths];
	}
	if(mainBundlePlugInsPath)
	{
		[array addObject:mainBundlePlugInsPath];
	}
	if([self initialisePerDomainPaths])
	{
		[array addObjectsFromArray:perDomainPaths];
	}
	if(extraPaths)
	{
		[array addObjectsFromArray:extraPaths];
	}
	return array;
}

- (void)setApplicationName:(NSString *)appName
{
	[applicationName release];
	applicationName = [appName retain];
}

- (void)setMainBundlePlugInsPath:(NSString *)path
{
	[mainBundlePlugInsPath release];
	mainBundlePlugInsPath = [path retain];
}

- (unsigned int)loadPlugIns
{
	NSString *path;
	NSEnumerator *en;
	unsigned int loaded;

	loaded = 0;
	en = [[self searchPath] objectEnumerator];
	while((path = [en nextObject]))
	{
		loaded += [self loadPlugInsAtPath:path];
	}
	return loaded;
}

- (void)resetDomainPaths
{
	[perDomainPaths release];
	perDomainPaths = nil;
}

- (BOOL)addPath:(NSString *)relativePath withinDirectory:(NSSearchPathDirectory)dir
{
	return [self addPath:relativePath withinDirectory:dir inDomains:NSAllDomainsMask];
}

- (BOOL)addPath:(NSString *)relativePath withinDirectory:(NSSearchPathDirectory)dir inDomains:(NSSearchPathDomainMask)mask
{
	NSArray *paths;
	NSEnumerator *en;
	NSString *path;
	
	if(!perDomainPaths)
	{
		if(!(perDomainPaths = [[NSMutableArray alloc] init]))
		{
			return NO;
		}
	}
	if((paths = NSSearchPathForDirectoriesInDomains(dir, mask, YES)))
	{
		en = [paths objectEnumerator];
		while((path = [en nextObject]))
		{
			[(NSMutableArray *)perDomainPaths addObject:[path stringByAppendingPathComponent:relativePath]];
		}
		return YES;
	}
	return NO;
}

- (void)resetLocalPaths
{
	[localPaths release];
	localPaths = [[NSMutableArray alloc] init];
	[self addBuiltInPlugInsFolderWithinBundle:[NSBundle mainBundle]];
}

- (BOOL)addPath:(NSString *)relativePath withinBundleWithIdentifier:(NSString *)bundle
{
	NSBundle *bndl;
	
	if((bndl = [NSBundle bundleWithIdentifier:bundle]))
	{
		return [self addPath:relativePath withinBundle:bndl];
	}
	return NO;
}

- (BOOL)addPath:(NSString *)relativePath withinBundle:(NSBundle *)bundle
{
	NSString *path;
	
	if((path = [bundle bundlePath]))
	{
		[(NSMutableArray *) localPaths addObject:[path stringByAppendingPathComponent:relativePath]];
		return YES;
	}
	return NO;
}	

- (BOOL)addBuiltInPlugInsFolderWithinBundleWithIdentifier:(NSString *)bundle
{
	NSBundle *bndl;
	
	if((bndl = [NSBundle bundleWithIdentifier:bundle]))
	{
		return [self addBuiltInPlugInsFolderWithinBundle:bndl];
	}
	return NO;
}

- (BOOL)addBuiltInPlugInsFolderWithinBundle:(NSBundle *)bundle
{
	NSString *path;
	
	if((path = [bundle builtInPlugInsPath]))
	{
		[(NSMutableArray *) localPaths addObject:path];
		return YES;
	}
	return NO;
}

# if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 
- (id<NGPlugInLoaderDelegate>)delegate
#else
- (id)delegate
#endif
{
	return delegate;
}

# if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 
- (void)setDelegate:(id<NGPlugInLoaderDelegate>)aDelegate
# else
- (void)setDelegate:(id)aDelegate
#endif
{
	delegate = aDelegate;
}

@end

@implementation NGPlugInLoader(NGPlugInLoaderInternalMethods)

- (unsigned int)loadPlugInsAtPath:(NSString *)folderPath
{
	NSDirectoryEnumerator *en;
	NSString *p;
	unsigned int loaded;
	
	NSLog(@"Loading plug-ins from path: %@", folderPath);
	loaded = 0;
	if(!(en = [[NSFileManager defaultManager] enumeratorAtPath:folderPath]))
	{
		return 0;
	}
	while(p = [en nextObject])
	{
		if([[p pathExtension] isEqualToString:bundleExtension])
		{
			if([self attemptToLoadPlugInAtPath:[folderPath stringByAppendingPathComponent:p]])
			{
				loaded++;
			}
		}
	}
	return loaded;
}

- (NSString *)nameOfBundle:(NSBundle *)bundle useOnlyCFBundleName:(BOOL)flag
{
	NSString *name;
	
	if(!(name = [[bundle objectForInfoDictionaryKey:@"CFBundleName"] retain]))
	{
		if(!flag)
		{
			name = [[[[bundle bundlePath] lastPathComponent] stringByDeletingPathExtension] retain];
		}
	}
	return name;
}

- (BOOL)attemptToLoadPlugInAtPath:(NSString *)bundlePath
{
	NSBundle *bundle;
	
	if(!(bundle = [NSBundle bundleWithPath:bundlePath]))
	{
		return NO;
	}
	if(!([self plugInShouldLoad:bundle]))
	{
		return NO;
	}
	if([bundle load])
	{
		[self plugInDidLoad:bundle];
		return YES;
	}
	return NO;
}

- (BOOL)plugInShouldLoad:(NSBundle *)bundle
{
	if(delegate && [delegate respondsToSelector:@selector(plugInShouldLoad:)])
	{
		return [delegate plugInShouldLoad:bundle];
	}
	return YES;
}

- (void)plugInDidLoad:(NSBundle *)bundle
{
	NSNotification *notification;
	
	notification = [NSNotification notificationWithName:NGPlugInLoaderPlugInDidLoadNotification object:bundle];
	if(delegate && [delegate respondsToSelector:@selector(plugInDidLoad:)])
	{
		[delegate plugInDidLoad:notification];
	}
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (BOOL)initialisePerDomainPaths
{
	if(perDomainPaths)
	{
		return YES;
	}
	if(!applicationName)
	{
		return NO;
	}
	return [self addPath:applicationName withinDirectory:NSApplicationSupportDirectory];
}

@end

