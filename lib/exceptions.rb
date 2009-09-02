class Trufina
  class TrufinaException < StandardError; end
  class ConfigFileError < TrufinaException; end
  class MissingToken < TrufinaException; end
  class MissingRequiredElements < TrufinaException; end
  class MissingRequiredAttributes < TrufinaException; end
  class InvalidElement < TrufinaException; end
  class NetworkError < TrufinaException; end
  class UnknownResponseType < TrufinaException; end
  class TrufinaResponseException < TrufinaException; end
end