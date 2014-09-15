//
//  BBUDraggedFile.m
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>

#import "BBUAssetUploadOperation.h"
#import "BBUDraggedFile.h"

@interface BBUDraggedFile ()

@property (nonatomic) CMAAsset* asset;
@property (nonatomic) NSDictionary* fileAttributes;
@property (nonatomic) NSImage* image;
@property (nonatomic) NSString* originalFileName;
@property (nonatomic) CMASpace* space;

@end

#pragma mark -

@implementation BBUDraggedFile

-(BBUAssetUploadOperation *)creationOperationForSpace:(CMASpace *)space {
    NSParameterAssert(space.defaultLocale);

    self.space = space;
    return [[BBUAssetUploadOperation alloc] initWithDraggedFile:self];
}

-(void)createWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    [self.space createAssetWithTitle:@{ self.space.defaultLocale: self.title ?: @"" }
                    description:nil
                   fileToUpload:nil
                        success:^(CDAResponse *response, CMAAsset *asset) {
                            self.asset = asset;

                            completionHandler(YES);
                        } failure:^(CDAResponse *response, NSError *error) {
                            self.error = error;

                            completionHandler(NO);
                        }];
}

-(void)deleteInternalWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    [self.asset deleteWithSuccess:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(YES);
        });
    } failure:^(CDAResponse *response, NSError *error) {
        self.error = error;

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(NO);
        });
    }];
}

-(void)deleteWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    if (self.asset.published) {
        [self.asset unpublishWithSuccess:^{
            [self deleteInternalWithCompletionHandler:completionHandler];
        } failure:^(CDAResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.error = error;

                completionHandler(NO);
            });
        }];
    } else {
        [self deleteInternalWithCompletionHandler:completionHandler];
    }
}

-(NSString *)description {
    return [NSString stringWithFormat:@"BBUDraggedFile with name '%@', attributes %@",
            self.originalFileName, self.fileAttributes];
}

-(void)fetchWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    [self.space fetchAssetWithIdentifier:self.asset.identifier success:^(CDAResponse *response,
                                                                         CMAAsset *asset) {
        self.asset = asset;

        completionHandler(YES);
    } failure:^(CDAResponse *response, NSError *error) {
        self.error = error;

        completionHandler(NO);
    }];
}

-(CGFloat)height {
    return self.image.size.height;
}

-(instancetype)initWithPasteboardItem:(NSPasteboardItem *)item {
    self = [super init];
    if (self) {
        NSString* urlString = [item stringForType:(NSString*)kUTTypeFileURL];
        NSURL* url = [NSURL URLWithString:urlString];

        self.fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path
                                                                               error:nil];
        self.image = [[NSImage alloc] initWithContentsOfURL:url];
        self.originalFileName = url.path.lastPathComponent;
    }
    return self;
}

-(NSUInteger)numberOfBytes {
    return [self.fileAttributes[NSFileSize] unsignedIntegerValue];
}

-(NSString *)title {
    return self.asset.title ?: [self.originalFileName stringByDeletingPathExtension];
}

-(void)updateWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    [self.asset updateWithSuccess:^{
        if (self.asset.fields[@"file"]) {
            [self.asset publishWithSuccess:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(YES);
                });
            } failure:^(CDAResponse *response, NSError *error) {
                self.error = error;

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(NO);
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(YES);
            });
        }
    } failure:^(CDAResponse *response, NSError *error) {
        self.error = error;

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(NO);
        });
    }];
}

-(NSURL *)url {
    if (!self.space.identifier || !self.asset.identifier) {
        return nil;
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://app.contentful.com/spaces/%@/assets/%@", self.space.identifier, self.asset.identifier]];
}

-(CGFloat)width {
    return self.image.size.width;
}

@end
