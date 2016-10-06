class PinsController < ApplicationController
  before_action :set_pin, only: [:show, :edit, :update, :destroy]
  before_action :correct_user, only: [:edit, :update, :destroy]
  before_action :authenticate_user!, except: [:index, :show]

  def index
    @pins = Pin.all
  end

  def show
  end

  def new
    @pin = current_user.pins.build
  end

  def edit
  end

  def create
    @pin = current_user.pins.build(pin_params)
    if @pin.save
      redirect_to @pin, notice: 'Pin was successfully created.'


      # Create user on Authy, will return an id on the object
      authy = Authy::API.register_user(
        email: @pin.email,
        cellphone: @pin.phone_number,
      )
      @pin.update(authy_id: authy.id)

      # Send an SMS to your user
      Authy::API.request_sms(id: @pin.authy_id)

      redirect_to verify_path

  def show_verify
    return redirect_to new_user_path unless session[:pin_id]
  end

  def verify
    @pin = current_user

    # Use Authy to send the verification token
    token = Authy::API.verify(id: @pin.authy_id, token: params[:token])

    if token.ok?
      # Mark the user as verified for get /user/:id
      @user.update(verified: true)

      # Send an SMS to the user 'success'
      send_message("You did it! Signup complete :)")

      # Show the user profile
      redirect_to user_path(@pin.id)
    else
      flash.now[:danger] = "Incorrect code, please try again"
      render :show_verify
    end
  end
    
  def resend
    @pin = current_user
    Authy::API.request_sms(id: @pin.authy_id)
    flash[:notice] = "Verification code re-sent"
    redirect_to verify_path
  end




    else
      render :new
    end
  end

  def update
    if @pin.update(pin_params)
      redirect_to @pin, notice: 'Pin was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @pin.destroy
    redirect_to pins_url
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pin
      @pin = Pin.find_by(id: params[:id])
    end

    def correct_user
      @pin = current_user.pins.find_by(id: params[:id])
      redirect_to pins_path, notice: "Not authorized to edit this pin" if @pin.nil?
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def pin_params
      params.require(:pin).permit(:description, :image)
    end



    def send_message(message)
      @pin = current_user
      twilio_number = ENV['201-355-4463']
      @client = Twilio::REST::Client.new ENV['AC88fbec4f1213cb7334ebc22b4de5c6e'], ENV['d5c3d34676acc8fc85915b29206ffa59x']
      message = @client.account.messages.create(
        :from => twilio_number,
        :to => @pin.phone_number,
        :body => message
      )
      puts message.to
    end
  end



end