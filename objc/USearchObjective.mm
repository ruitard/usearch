#import "USearchObjective.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#import "punned.hpp"
#pragma clang diagnostic pop

using namespace unum::usearch;
using namespace unum;

using distance_t = punned_distance_t;
using punned_t = punned_gt<UInt32>;
using shared_index_t = std::shared_ptr<punned_t>;

@interface Index ()

@property (readonly) shared_index_t native;

- (instancetype)initWithIndex:(shared_index_t)native;

@end

@implementation Index

- (instancetype)initWithIndex:(shared_index_t)native {
    self = [super init];
    _native = native;
    return self;
}

- (Boolean)isEmpty {
    return _native->size() != 0;
}

- (UInt32)dimensions {
    return static_cast<UInt32>(_native->dimensions());
}

- (UInt32)connectivity {
    return static_cast<UInt32>(_native->connectivity());
}

- (UInt32)length {
    return static_cast<UInt32>(_native->size());
}

- (UInt32)capacity {
    return static_cast<UInt32>(_native->capacity());
}

- (UInt32)expansion_add {
    return static_cast<UInt32>(_native->config().expansion_add);
}

- (UInt32)expansion_search {
    return static_cast<UInt32>(_native->config().expansion_search);
}

+ (instancetype)indexIP:(UInt32)dimensions connectivity:(UInt32)connectivity {
    std::size_t dims = static_cast<std::size_t>(dimensions);
    index_config_t config;

    config.connectivity = static_cast<std::size_t>(connectivity);
    shared_index_t ptr = std::make_shared<punned_t>(punned_t::ip(dims, accuracy_t::f32_k, config));
    return [[Index alloc] initWithIndex:ptr];
}

+ (instancetype)indexL2sq:(UInt32)dimensions connectivity:(UInt32)connectivity {
    std::size_t dims = static_cast<std::size_t>(dimensions);
    index_config_t config;

    config.connectivity = static_cast<std::size_t>(connectivity);
    shared_index_t ptr = std::make_shared<punned_t>(punned_t::l2sq(dims, accuracy_t::f32_k, config));
    return [[Index alloc] initWithIndex:ptr];
}

+ (instancetype)indexHaversine:(UInt32)connectivity {
    index_config_t config;

    config.connectivity = static_cast<std::size_t>(connectivity);
    shared_index_t ptr = std::make_shared<punned_t>(punned_t::haversine(accuracy_t::f32_k, config));
    return [[Index alloc] initWithIndex:ptr];
}

- (void)addSingle:(UInt32)label
           vector:(Float32 const *_Nonnull)vector {
    _native->add(label, vector);
}

- (UInt32)searchSingle:(Float32 const *_Nonnull)vector
                 count:(UInt32)wanted
                labels:(UInt32 *_Nullable)labels
             distances:(Float32 *_Nullable)distances {
    std::size_t found = _native->search(vector, static_cast<std::size_t>(wanted)).dump_to(labels, distances);

    return static_cast<UInt32>(found);
}

- (void)addPrecise:(UInt32)label
            vector:(Float64 const *_Nonnull)vector {
    _native->add(label, (f64_t const *)vector);
}

- (UInt32)searchPrecise:(Float64 const *_Nonnull)vector
                  count:(UInt32)wanted
                 labels:(UInt32 *_Nullable)labels
              distances:(Float32 *_Nullable)distances {
    std::size_t found = _native->search((f64_t const *)vector, static_cast<std::size_t>(wanted)).dump_to(labels, distances);

    return static_cast<UInt32>(found);
}

- (void)addImprecise:(UInt32)label
              vector:(void const *_Nonnull)vector {
    _native->add(label, (f16_bits_t const *)vector);
}

- (UInt32)searchImprecise:(void const *_Nonnull)vector
                    count:(UInt32)wanted
                   labels:(UInt32 *_Nullable)labels
                distances:(Float32 *_Nullable)distances {
    std::size_t found = _native->search((f16_bits_t const *)vector, static_cast<std::size_t>(wanted)).dump_to(labels, distances);

    return static_cast<UInt32>(found);
}

- (void)clear {
    _native->clear();
}

- (void)save:(NSString *)path {
    char const *path_c = [path UTF8String];

    if (!path_c) {
        @throw [NSException exceptionWithName:@"Can't save to disk"
                                       reason:@"The path must be convertible to UTF8"
                                     userInfo:nil];
    }

    _native->save(path_c);
}

- (void)load:(NSString *)path {
    char const *path_c = [path UTF8String];

    if (!path_c) {
        @throw [NSException exceptionWithName:@"Can't load from disk"
                                       reason:@"The path must be convertible to UTF8"
                                     userInfo:nil];
    }

    _native->load(path_c);
}

- (void)view:(NSString *)path {
    char const *path_c = [path UTF8String];

    if (!path_c) {
        @throw [NSException exceptionWithName:@"Can't view from disk"
                                       reason:@"The path must be convertible to UTF8"
                                     userInfo:nil];
    }

    _native->view(path_c);
}

@end
