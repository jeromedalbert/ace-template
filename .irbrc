require 'amazing_print'

AmazingPrint.irb!
AmazingPrint.rdbg!
AmazingPrint.defaults = { hash_format: :rocket }

IRB.conf[:USE_AUTOCOMPLETE] = false
