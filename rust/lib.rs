#[cxx::bridge]
pub mod ffi {
    
    // Shared structs with fields visible to both languages.
    struct Matches {
        count: usize,
        labels: Vec<u32>,
        distances: Vec<f32>,
    }

    // C++ types and signatures exposed to Rust.
    unsafe extern "C++" {
        include!("lib.hpp");

        type Index;

        pub fn new_ip(dimensions: usize, quantization: &str, connectivity: usize, expansion_add: usize, expansion_search: usize) -> Result<UniquePtr<Index>>;
        pub fn new_l2sq(dimensions: usize, quantization: &str, connectivity: usize, expansion_add: usize, expansion_search: usize) -> Result<UniquePtr<Index>>;
        pub fn new_cos(dimensions: usize, quantization: &str, connectivity: usize, expansion_add: usize, expansion_search: usize) -> Result<UniquePtr<Index>>;
        pub fn new_haversine(quantization: &str, connectivity: usize, expansion_add: usize, expansion_search: usize) -> Result<UniquePtr<Index>>;

        pub fn reserve(self: &Index, capacity: usize) -> Result<()>;

        pub fn dimensions(self: &Index) -> usize;
        pub fn connectivity(self: &Index) -> usize;
        pub fn size(self: &Index) -> usize;
        pub fn capacity(self: &Index) -> usize;

        pub fn add(self: &Index, label: u32, vector: &[f32]) -> Result<()>;
        pub fn search(self: &Index, query: &[f32], count: usize) -> Result<Matches>;

        pub fn add_in_thread(self: &Index, label: u32, vector: &[f32], thread: usize) -> Result<()>;
        pub fn search_in_thread(self: &Index, query: &[f32], count: usize, thread: usize) -> Result<Matches>;

        pub fn save(self: &Index, path: &str) -> Result<()>;
        pub fn load(self: &Index, path: &str) -> Result<()>;
        pub fn view(self: &Index, path: &str) -> Result<()>;
    }
}


#[cfg(test)]
mod tests {
    use crate::ffi::new_ip;
    use crate::ffi::new_l2sq;
    use crate::ffi::new_cos;
    use crate::ffi::new_haversine;

    #[test]
    fn integration() {

        let quant = "f16";
        let index = new_ip(5,  &quant, 0, 0, 0).unwrap();
    
        assert!(index.reserve(10).is_ok());
        assert!(index.capacity() >= 10);
        assert!(index.connectivity() != 0);
        assert_eq!(index.dimensions(), 5);
        assert_eq!(index.size(), 0);
    
        let first: [f32; 5] = [0.2, 0.1, 0.2, 0.1, 0.3];
        let second: [f32; 5] = [0.2, 0.1, 0.2, 0.1, 0.3];
    
        assert!(index.add(42, &first).is_ok());
        assert!(index.add(43, &second).is_ok());
        assert_eq!(index.size(), 2);
    
        // Read back the tags
        let results = index.search(&first, 10).unwrap();
        assert_eq!(results.count, 2);
    
        // Validate serialization
        assert!(index.save("index.rust.usearch").is_ok());
        assert!(index.load("index.rust.usearch").is_ok());
        assert!(index.view("index.rust.usearch").is_ok());
    
        // Make sure every function is called at least once
        assert!(new_ip(5,  &quant, 0, 0, 0).is_ok());
        assert!(new_l2sq(5,  &quant, 0, 0, 0).is_ok());
        assert!(new_cos(5,  &quant, 0, 0, 0).is_ok());
        assert!(new_haversine(&quant, 0, 0, 0).is_ok());
    }
}