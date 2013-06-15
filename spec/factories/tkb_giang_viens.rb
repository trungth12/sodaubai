# Read about factories at https://github.com/thoughtbot/factory_girl
require "date"
FactoryGirl.define do
  factory :tkb_giang_vien do
    giang_vien
    lop_mon_hoc    
    phong "MyString"
    nam_hoc "MyString"
    hoc_ky 2
    tuan_hoc_bat_dau 23
    so_tuan 10
    ngay_bat_dau Date.strptime("2013-05-09","%Y-%m-%d") 
    ngay_ket_thuc Date.strptime("2013-10-09","%Y-%m-%d")
    so_tiet 3
    sequence(:tiet_bat_dau) {|n| n }
    sequence(:thu) { |n| n+1 }
  end
end
