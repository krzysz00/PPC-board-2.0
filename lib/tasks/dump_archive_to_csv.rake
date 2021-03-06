#Usage: rake db:dump_archive > file
require 'csv'
namespace :db do
  desc "Dump the archive to a CSV file"
  task :dump_archive => :environment do
    ActiveRecord::Base.logger.level = Logger::INFO
    roots = Post.where(:ancestry => nil, :next_version_id => nil,
                       :user_id => User.find_by_name("Archive Script").id)
      .order("sort_timestamp DESC")
    CSV($stdout) do |csv|
      csv << ["id", "sort_timestamp", "ancestry", "author", "subject", "body"]
      def recurse(tree,csv)
        tree.each do |k,v|
          csv << [k.id, k.sort_timestamp, k.ancestry, k.author, k.subject, k.body]
          recurse(v,csv)
        end
      end
      roots.each do |root|
        posts = Post.arrange_nodes(
          root.subtree
          .select(:body)
          .order("ancestry NULLS FIRST, sort_timestamp DESC").load)
        recurse(posts,csv)
      end
    end
  end
end
