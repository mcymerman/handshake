# Codes, message text, zones, location cells and reveal details never reach logs.
# These names also filter SQL bind values and #inspect output.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :code, :digest, :digits, :body, :zone, :neighbor, :cell, :lat, :lng, :word,
  :first_name, :photo, :social, :phone, :note, :evidence, :ip
]
