Pod::Spec.new do |s|
  s.name         = "MTStackViewController"
  s.version      = "0.0.1"
  s.summary      = "A short description of MTStackViewController."
  s.homepage     = "https://github.com/willowtreeapps/MTStackViewController"
  s.license      = 'Commercial'
  s.author       = { "WillowTree Apps" => "" }
  s.source       = { :git => "git@github.com:willowtreeapps/MTStackViewController.git", :tag => s.version }
  s.source_files = 'Classes', 'Classes/**/*.{h,m}'
  s.requires_arc = true
end
