Pod::Spec.new do |s|
  s.name         = "MTStackViewController"
  s.version      = "0.0.5"
  s.summary      = "A container view controller which provides Facebook / Path style navigation."
  s.homepage     = "https://github.com/willowtreeapps/MTStackViewController"
  s.license      = 'Commercial'
  s.author       = { "WillowTree Apps" => "" }
  s.source       = { :git => "git@github.com:willowtreeapps/MTStackViewController.git", :tag => s.version }
  s.source_files = 'Classes'
  s.requires_arc = true
  s.frameworks = 'QuartzCore'
  s.platform = :ios, '5.0'
end
