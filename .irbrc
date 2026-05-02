require 'amazing_print'

AmazingPrint.irb!
AmazingPrint.rdbg!
AmazingPrint.defaults = { hash_format: :rocket, colors: :values_only }

IRB.conf[:USE_AUTOCOMPLETE] = false
