module Lti
  class Request
    def get(url)
      data = RestClient.get(request_url(url), headers)
      JSON.parse(data)
    end

    def post(url, payload: {})
      data = RestClient.post(request_url(url), payload, headers)
      JSON.parse(data)
    end

    def delete(url, payload: {})
      RestClient::Request.execute(method: :delete, url: request_url(url), payload:, headers:)
    end
  end
end
