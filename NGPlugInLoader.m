

#import "NGPlugInLoader.h"

@interface NGPlugInLoader(NGPlugInLoaderInternalMethods)
- (NSArray *)aggregatePaths;
- (NSArray *)defaultSearchPaths;
- (NSString *)nameOfBundle:(NSBundle *)bundle useOnlyCFBundleName:(BOOL)flag;
- (BOOL)loadPlugInsAtPath:(NSString *)folderPath;
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
		searchPaths = nil;
		frameworkIdentifier = nil;
		if((applicationName = [self nameOfBundle:[NSBundle mainBundle] useOnlyCFBundleName:YES]))
		{
			appPlugInsFolderPath = [[NSString alloc] initWithFormat:@"Application Support/%@/PlugIns", applicationName];
		}
		else
		{
			appPlugInsFolderPath = nil;
		}
		appBundlePlugInsPath = [[[NSBundle mainBundle] builtInPlugInsPath] retain];
		frameworkPlugInsFolderPath = nil;
		frameworkBundlePlugInsPath = nil;
		useDefaultSearchPaths = YES;
	}
	return self;
}

- (void) release
{
	[bundleExtension release];
	[appPlugInsFolderPath release];
	[frameworkPlugInsFolderPath release];
	[appBundlePlugInsPath release];
	[frameworkBundlePlugInsPath release];
	[searchPaths release];
	[defaultSearchPaths release];
	[applicationName release];
	[frameworkIdentifier release];
	[super release];
}

- (NSArray *)searchPaths
{
	if(useDefaultSearchPaths)
	{
		if(!defaultSearchPaths)
		{
			defaultSearchPaths = [[self defaultSearchPaths] retain];
		}
		if(searchPaths)
		{
			return [self aggregatePaths];
		}
		return defaultSearchPaths;
	}
	if(searchPaths)
	{
		return searchPaths;
	}
	return [NSArray array];
}

- (void)addSearchPath:(NSString *)path
{
	if(!searchPaths)
	{
		searchPaths = [[NSMutableArray alloc] init];
	}
	[(NSMutableArray *)searchPaths addObject:path];
}

- (void)setSearchPaths:(NSArray *)paths
{
	[self setSearchPaths:paths replacingDefaults:NO];
}

- (void)setSearchPaths:(NSArray *)paths replacingDefaults:(BOOL)replace
{
	[searchPaths release];
	if(replace)
	{
		[defaultSearchPaths release];
		defaultSearchPaths = nil;
		useDefaultSearchPaths = NO;
	}
	else
	{
		useDefaultSearchPaths = YES;
	}
	if(paths)
	{
		searchPaths = [[NSMutableArray alloc] initWithArray:paths];
	}
	else
	{
		searchPaths = nil;
	}
}

- (void)setApplicationName:(NSString *)appName
{
	if((applicationName && appName && NSOrderedSame == [applicationName compare:appName]) ||
		(!applicationName && !appName))
	{
		return;
	}
	[applicationName release];
	[appPlugInsFolderPath release];
	if((applicationName = [appName retain]))
	{
		appPlugInsFolderPath = [[NSString alloc] initWithFormat:@"Application Support/%@/PlugIns", applicationName];
	}
	else
	{
		appPlugInsFolderPath = nil;
	}
   [defaultSearchPaths release];
   defaultSearchPaths = nil;
}

- (void)setFrameworkWithIdentifier:(NSString *)identifier
{
	[self setFrameworkWithBundle:[NSBundle bundleWithIdentifier:identifier]];
}

- (void)setFrameworkWithBundle:(NSBundle *)bundle
{
	NSString *path;
	
	if(bundle)
	{
		path = [bundle builtInPlugInsPath];
	}
	else
	{
		path = nil;
	}
	if((frameworkBundlePlugInsPath && path && NSOrderedSame == [frameworkBundlePlugInsPath compare:path]) ||
	   (!frameworkBundlePlugInsPath && !path))
	{
		return;
	}
	[frameworkBundlePlugInsPath release];
	frameworkBundlePlugInsPath = [path retain];
	[defaultSearchPaths release];
	defaultSearchPaths = nil;
}	

- (unsigned int)loadPlugIns
{
	return 0;
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

/* This will only be called if useDefaultSearchPaths is YES and searchPaths
 * is non-nil.
 */
- (NSArray *)aggregatePaths
{
	if(defaultSearchPaths)
	{
		return [defaultSearchPaths arrayByAddingObjectsFromArray:searchPaths];
	}
	return searchPaths;
}

- (NSArray *)defaultSearchPaths
{
	NSEnumerator *en;
	NSArray *libpaths;
	NSMutableArray *paths;
	NSString *dir;
	
	paths = [NSMutableArray array];
	if(frameworkBundlePlugInsPath) [paths addObject:frameworkBundlePlugInsPath];
	if(appBundlePlugInsPath) [paths addObject:appBundlePlugInsPath];
	if(appPlugInsFolderPath || frameworkPlugInsFolderPath)
	{
		libpaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
		en = [libpaths objectEnumerator];
		while((dir = [en nextObject]))
		{
			if(appPlugInsFolderPath)
			{
				[paths addObject:[dir stringByAppendingPathComponent:appPlugInsFolderPath]];
			}
			if(frameworkPlugInsFolderPath)
			{
				[paths addObject:[dir stringByAppendingPathComponent:frameworkPlugInsFolderPath]];
			}
		}
	}
	return paths;
}

- (BOOL)loadPlugInsAtPath:(NSString *)folderPath
{
	NSDirectoryEnumerator *en;
	NSString *p;
	
	NSLog(@"Loading plug-ins from path: %@", folderPath);
	if(!(en = [[NSFileManager defaultManager] enumeratorAtPath:folderPath]))
	{
		return NO;
	}
	while(p = [en nextObject])
	{
		if([[p pathExtension] isEqualToString:bundleExtension])
		{
/* 			[self loadDriverFromBundle:[folderPath stringByAppendingPathComponent:p]]; */
			NSLog(@"Loading plug-ins from path: %@", folderPath);
		}
	}
	return YES;
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

@end
