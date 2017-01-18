module Slather
  module CoverageService
    module Coveralls

      def coverage_file_class
        if input_format == "profdata"
          Slather::ProfdataCoverageFile
        else
          Slather::CoverageFile
        end
      end
      private :coverage_file_class

      def travis_job_id
        ENV['TRAVIS_JOB_ID']
      end
      private :travis_job_id

      def circleci_job_id
        ENV['CIRCLE_BUILD_NUM']
      end
      private :circleci_job_id

      def circleci_pull_request
        ENV['CIRCLE_PR_NUMBER'] || ENV['CI_PULL_REQUEST'] || ""
      end
      private :circleci_pull_request

      def jenkins_job_id
        ENV['BUILD_ID']
      end
      private :jenkins_job_id

      def jenkins_branch_name
        branch_name = ENV['GIT_BRANCH']
        if branch_name.include? 'origin/'
          branch_name[7...branch_name.length]
        else
          branch_name
        end
      end
      private :jenkins_branch_name

      def buildkite_job_id
        ENV['BUILDKITE_BUILD_NUMBER']
      end
      private :buildkite_job_id

      def buildkite_pull_request
        ENV['BUILDKITE_PULL_REQUEST']
      end
      private :buildkite_pull_request

      def jenkins_git_info
        {
          head: {
            id: ENV['sha1'],
            author_name: ENV['ghprbActualCommitAuthor'],
            message: ENV['ghprbPullTitle']
          },
          branch: jenkins_branch_name
        }
      end
      private :jenkins_git_info

      def circleci_build_url
        "https://circleci.com/gh/" + ENV['CIRCLE_PROJECT_USERNAME'] || "" + "/" + ENV['CIRCLE_PROJECT_REPONAME'] || "" + "/" + ENV['CIRCLE_BUILD_NUM'] || ""
      end
      private :circleci_build_url

      def circleci_git_info
        {
          :head => {
            :id => (ENV['CIRCLE_SHA1'] || ""),
            :author_name => (ENV['CIRCLE_PR_USERNAME'] || ENV['CIRCLE_USERNAME'] || ""),
            :message => (`git log --format=%s -n 1 HEAD`.chomp || "")
          },
          :branch => (ENV['CIRCLE_BRANCH'] || "")
        }
      end
      private :circleci_git_info

      def buildkite_git_info
        {
          :head => {
            :id => ENV['BUILDKITE_COMMIT'],D
          },
          :branch => ENV['BUILDKITE_BRANCH']
        }
      end

      def buildkite_build_url
        "https://buildkite.com/" + ENV['BUILDKITE_PROJECT_SLUG'] + "/builds/" + ENV['BUILDKITE_BUILD_NUMBER'] + "#"
      end

      def coveralls_coverage_data
          coveralls_hash = {
                :service_name => "bitrise",
                :author_name => (`git log --format=%an -n 1 HEAD`.chomp || ""),
                :author_email => (`git log --format=%ae -n 1 HEAD`.chomp || ""),
                :message => (`git log --format=%s -n 1 HEAD`.chomp || ""),
                :branch_name => jenkins_branch_name,
                :repo_token => coverage_access_token,
                :source_files => coverage_files.map(&:as_json)
              }
          coveralls_hash.to_json
      end
      private :coveralls_coverage_data

      def post
        f = File.open('coveralls_json_file', 'w+')
        begin
          f.write(coveralls_coverage_data)
          f.close

          curl_result = `curl -s --form json_file=@#{f.path} #{coveralls_api_jobs_path}`

          if curl_result.is_a? String 
            curl_result_json = JSON.parse(curl_result)          

            if curl_result_json["error"]
              error_message = curl_result_json["message"]
              raise StandardError, "Error while uploading coverage data to Coveralls. CI Service: #{ci_service} Message: #{error_message}"
            end
          end

        rescue StandardError => e
          FileUtils.rm(f)
          raise e
        end
        FileUtils.rm(f)
      end

      def coveralls_api_jobs_path
        "https://coveralls.io/api/v1/jobs"
      end
      private :coveralls_api_jobs_path

    end
  end
end
