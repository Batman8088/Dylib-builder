#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <objc/runtime.h>

@interface FolderDelegateProxy : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, weak) id<UIDocumentPickerDelegate> originalDelegate;
@end

@implementation FolderDelegateProxy

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    // Unlock security-scoped access for every selected folder URL
    for (NSURL *url in urls) {
        [url startAccessingSecurityScopedResource];
    }

    if ([self.originalDelegate respondsToSelector:@selector(documentPicker:didPickDocumentsAtURLs:)]) {
        [self.originalDelegate documentPicker:controller didPickDocumentsAtURLs:urls];
    }
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    if ([self.originalDelegate respondsToSelector:@selector(documentPickerWasCancelled:)]) {
        [self.originalDelegate documentPickerWasCancelled:controller];
    }
}

// Forward any other delegate calls directly to the app's original delegate
- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.originalDelegate respondsToSelector:aSelector]) {
        return self.originalDelegate;
    }
    return [super forwardingTargetForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [super respondsToSelector:aSelector] || [self.originalDelegate respondsToSelector:aSelector];
}

@end

static char kProxyKey;

%hook UIDocumentPickerViewController

// Hook modern iOS 26+ initializer (with asCopy parameter)
- (instancetype)initForOpeningContentTypes:(NSArray<UTType *> *)contentTypes asCopy:(BOOL)asCopy {
    // Directories cannot be opened with asCopy:YES; must be NO
    return %orig(@[UTTypeFolder], NO);
}

// Hook modern iOS 26+ convenience initializer
- (instancetype)initForOpeningContentTypes:(NSArray<UTType *> *)contentTypes {
    return [self initForOpeningContentTypes:@[UTTypeFolder] asCopy:NO];
}

// Hook legacy iOS 26 and older initializer
- (instancetype)initWithDocumentTypes:(NSArray<NSString *> *)allowedUTIs inMode:(UIDocumentPickerMode)mode {
    return %orig(@[@"public.folder"], UIDocumentPickerModeOpen);
}

// Wrap the delegate to automatically unlock security-scoped folder access
- (void)setDelegate:(id<UIDocumentPickerDelegate>)delegate {
    if (!delegate || [delegate isKindOfClass:[FolderDelegateProxy class]]) {
        %orig(delegate);
        return;
    }
    FolderDelegateProxy *proxy = [[FolderDelegateProxy alloc] init];
    proxy.originalDelegate = delegate;
    objc_setAssociatedObject(self, &kProxyKey, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    %orig(proxy);
}

%end
