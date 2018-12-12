
class CMGrafana

  module CoreMedia

    module Folder


      def create_host_folder(folder_name)

        create_folder(uid: folder_name, title: folder_name)
      end

      def delete_host_folder(folder_name)

        delete_folder(folder_name)
      end

    end
  end
end
