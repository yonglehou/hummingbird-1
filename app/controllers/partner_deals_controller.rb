class PartnerDealsController < ApplicationController
  before_action :authenticate_user!, only: [:update]

  def index
    # todo: return only deals available in users country
    render json: PartnerDeal.joins(:codes)
      .where(active: true)
      .having('count(partner_codes.id) > 0')
      .group('partner_deals.id'),
      each_serializer: PartnerDealSerializer
  end

  # redeem a code
  def update
    unless current_user.pro?
      return head :unauthorized
    end

    deal = PartnerDeal.find(params[:id])
    # has this user redeemed a code?
    code = deal.codes.where(user: current_user).last
    if code.nil?
      # todo: deal with potential race condition
      code = deal.codes.unclaimed.first
      code.update_attributes!(user: current_user, claimed_at: DateTime.now)
    elsif deal.recurring?
      # todo: re-issue another coupon if claim is over a month old
    end

    # output the redeemed code
    render text: code.code unless code.nil?
  end
end
