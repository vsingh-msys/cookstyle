#
# Copyright:: 2020, Chef Software, Inc.
# Author:: Tim Smith (<tsmith@chef.io>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module RuboCop
  module Cop
    module Chef
      module ChefCorrectness
        # Don't use Ruby to shellout in a only_if / not_if conditional when you can just shellout directly. Any string value used with only_if / not_if is executed in your system's shell and the return code of the command is the result for the not_if / only_if determination.
        #
        # @example
        #
        #   # bad
        #   cookbook_file '/logs/foo/error.log' do
        #     source 'error.log'
        #     only_if { system('wget https://www.bar.com/foobar.txt -O /dev/null') }
        #   end
        #
        #   cookbook_file '/logs/foo/error.log' do
        #     source 'error.log'
        #     only_if { shell_out('wget https://www.bar.com/foobar.txt -O /dev/null').exitstatus == 0 }
        #   end
        #
        #   # good
        #   cookbook_file '/logs/foo/error.log' do
        #     source 'error.log'
        #     only_if 'wget https://www.bar.com/foobar.txt -O /dev/null'
        #   end
        #
        class ConditionalRubyShellout < Cop
          include RuboCop::Chef::CookbookHelpers
          MSG = "Don't use Ruby to shellout in an only_if / not_if conditional when you can shellout directly by wrapping the command in quotes.".freeze

          def_node_matcher :conditional_shellout?, <<-PATTERN
          (block
            (send nil? ${:only_if :not_if})
            (args)
            {(send nil? :system $(str ...))
             (send (send (send nil? :shell_out $(str ...)) :exitstatus) :== (int 0))
              })
          PATTERN

          def on_block(node)
            conditional_shellout?(node) do
              add_offense(node, location: :expression, message: MSG, severity: :refactor)
            end
          end

          def autocorrect(node)
            lambda do |corrector|
              conditional_shellout?(node) do |type, val|
                corrector.replace(node.loc.expression, "#{type} #{val.source}")
              end
            end
          end
        end
      end
    end
  end
end
