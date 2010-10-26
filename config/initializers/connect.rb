FACEBOOK_TOKEN = case Rails.env
  when "development"
    "858ceea853f0978e9e881c14ab53051e"
  else
    "129f456584787dd5f00ecf3c0d421fdd"
end

FACEBOOK_SECRET = case Rails.env
  when "development"
    "988920d6d6c30d7b79e5de5cc43abc11"
  else
    "dcba05da45f5f2ba96cd4ad9005c8280"
end



FLICKR_TOKEN = case Rails.env
  when "development"
    "3637b1f30cfa0503eedf9aaca8a4c371"
  else
    "afe0c7d3e7b03ae1e5d78e42f8417680"
end

FLICKR_SECRET = case Rails.env
  when "development"
    "3571d29d7a1c068a"
  else
    "c9537f874233f39d"
end




