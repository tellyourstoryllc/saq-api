# Remove AUTO_INCREMENTs from tables in the SQL dump to avoid git diff noise
namespace :db do
  namespace :structure do
    task :dump do
      path = Rails.root.join('db', 'structure.sql')
      contents = File.read(path)
      File.open(path, 'w'){ |file| file.write(contents.gsub(/ AUTO_INCREMENT=\d*/, '')) }
    end
  end
end
