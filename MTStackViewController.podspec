Pod::Spec.new do |s|
  s.name         = "MTStackViewController"
  s.version      = "2.2.2"
  s.summary      = "A container view controller which provides Facebook / Path style navigation."
  s.homepage     = "https://github.com/willowtreeapps/MTStackViewController"
  s.license      = 'MIT'
  s.author       = { "WillowTree Apps" => "" }
  s.source       = { :git => "https://github.com/willowtreeapps/MTStackViewController.git", :tag => s.version }
  s.source_files = 'Classes/**/*.{h,m}'
  s.requires_arc = true
  s.frameworks = 'QuartzCore'
  s.platform = :ios, '5.0'
end
