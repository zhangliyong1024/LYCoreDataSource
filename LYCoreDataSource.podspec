Pod::Spec.new do |s|
s.name         = 'LYCoreDataSource'
s.version      = '1.1.3'
s.summary      = 'CoreData Helper'
s.homepage     = 'https://github.com/zhangliyong1024/LYCoreDataSource'
s.license      = 'MIT'
s.authors      = { "zhangliyong" => "zhangliyong1997@gmail.com" }
s.platform     = :ios, '8.0'
s.source       = {:git => 'https://github.com/zhangliyong1024/LYCoreDataSource.git', :tag => s.version}
s.source_files = 'LYCoreDataSourceDemo/LYCoreDataSource/**/*.{h,m}'
s.requires_arc = true
end
