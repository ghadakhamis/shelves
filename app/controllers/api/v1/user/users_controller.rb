module Api::V1::User
  class Api::V1::User::UsersController < ApplicationController
      before_action :authenticate_request, only: [:update, :show , :get_user_books]
     
      # POST /signup
      # return authenticated token upon signup
      def create
        @user = User.create!(user_params)
        #@user.profile_picture = "/assets/images/default_profile.jpg"
        if @user.save
          UserMailer.registration_confirmation(@user).deliver
        auth_token = AuthenticateUser.new(@user.email, @user.password).call
        response = {status: 'SUCCESS', message: Message.account_created, auth_token: auth_token }
        render json: response, status: :created
      else
          head(:unprocessable_entity)
        end
      end

      def confirm_email
          user=User.find_by_confirm_token(params[:id])
          if user
            user.email_activate
            render json: {status: 'SUCCESS', message: "Your account has now been confirmed.You can login now !"}, status: :ok
          else 
            render json: {status: 'FAIL', message: "Something went wrong!"}, status: :notfound
        end
        
      end
      def update
        @user=User.find(params[:id]) 
        @user.update(user_complete_params)
        if params[:phone]
          
          newPhones = params[:phone].values
          
        #   phonesarray = JSON.parse(newPhone)
          @phones = Phone.where(user_id: @user.id )
          @phones.each do |oldphone|
            if newPhones.include?(oldphone.phone) == false
              oldphone.destroy
            end #end if 
          end  #end do
          newPhones.each do |tel|
            flag=0 #means that new phone not included in old ones 
            @phones.each do |old|
            if tel == old.phone
              flag=1
            end #end if 
          end  #end do
            if flag == 0
              @phone = Phone.new(user_id: @user.id, phone: tel)
              @phone.save
            end #end if
            end #end do
           
          end # end if 
        if params[:building_number]
          b_number = params[:building_number].values
          st=params[:street].values
          reg=params[:region].values
          newCity = params[:city].values
          code = params[:postal_code].values
          @addresses= Address.where(user_id: @user.id )
          @addresses.each do |oldAddr|
            if b_number.include?(oldAddr.building_number.to_s) == false || st.include?(oldAddr.street) == false || reg.include?(oldAddr.region) == false || newCity.include?(oldAddr.city) == false ||  code.include?(oldAddr.postal_code) == false 
              oldAddr.destroy
            end  #end if
          end #end do
          i=0
          b_number.each do |bno|
            flag = 0 #flag is 0 if new address is not included in old ones
            @addresses.each do |oldAddress|
              if bno == oldAddress.building_number.to_s && st[i] == oldAddress.street && reg[i] == oldAddress.region && newCity[i] == oldAddress.city && code[i] == oldAddress.postal_code.to_s
                flag = 1
            end #end if 
            end #end do 
            if flag == 0
              @address = Address.new(user_id: @user.id, building_number: bno, street: st[i], region: reg[i], city: newCity[i], postal_code: code[i])
              @address.save
            end 
        i+=1
          end #end do
        end #end if 
        @user.categories.each do |userCateg|
          if params[userCateg.name] == nil
            @user.categories.delete(userCateg)
          end
        end
        @interests = Category.all
        @interests.each do |interest|
          if params[interest.name]
            if @user.categories.include?(interest) == false
              @user.categories << interest
            end
          end
        end
        render json: {status: 'SUCCESS', message: "Profile updated", user: current_user , phones: current_user.phones , addresses: current_user.addresses},  :except => [:password_digest], status: :ok
      end #end method

      def destroy
      end

      #### get current user info
      def show
        @user = @current_user
        @books = Book.all
        @user_books = Array.new
        for book in @books
            if book.user_id == @current_user.id 
              @user_books << book
            end
        end
        render json: {status: 'SUCCESS', :user => @user, books: @user_books,  auth_token: request.headers['Authorization'], phones: @user.phones, addresses: @user.addresses}, :except => [:password_digest],status: :ok
      end
      #### get user books ####
      def get_user_books
        if  User.exists?(:id => params[:id])
            @user_books= Book.where(:user_id => params[:id])
            render :json => @user_books, each_serializer: BookSerializer
            #render json: {status: 'SUCCESS', message: 'Loaded notification_messages successfully', notification_messages:@notification_messages},status: :ok
        else
            render json: {status: 'FAIL', message: 'user not found'},status: :ok
        end
      end
      private
      #### Authentication of user ####
      def authenticate_request
          @current_user = AuthorizeApiRequest.call(request.headers).result
          render json: { error: 'Not Authorized' }, status: 401 unless @current_user
      end
      
      def user_params
        params.permit(
          :name,
          :email,
          :password,
          :password_confirmation, 
          :role
        )
    end
    def user_complete_params
      params.permit(
        :name,
        :email, 
        :profile_picture,
        :gender,
        phone: [],
        building_number: [],
        street: [],
        region: [],
        city: [],
        postal_code: []
      )
    end


  end
end
