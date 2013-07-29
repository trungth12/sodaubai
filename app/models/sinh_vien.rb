class SinhVien < ActiveRecord::Base
  attr_accessible :gioi_tinh, :ho_dem, :lop_hc, :ma_he_dao_tao, :ma_khoa_hoc, :ma_nganh, :ma_sinh_vien, :ngay_sinh, :ten, :trang_thai, :ten_nganh, :ngay

  validates :ma_sinh_vien, :uniqueness => { :case_sensitive => false }
  validates :ma_sinh_vien, :trang_thai, :presence => true

  has_one :user, :as => :imageable
  delegate :username, :to => :user
  has_one :can_bo_lop, :foreign_key => 'ma_sinh_vien', :primary_key => 'ma_sinh_vien'
  has_many :lop_mon_hoc_sinh_viens, :foreign_key => 'ma_sinh_vien', :primary_key => 'ma_sinh_vien', :dependent => :destroy
      
  has_many :diem_chuyen_cans, :foreign_key => 'ma_sinh_vien', :primary_key => 'ma_sinh_vien', :dependent => :destroy do 
  	def with_lop(ma_lop, ma_mon)
  		where("diem_chuyen_cans.ma_lop" => ma_lop, "diem_chuyen_cans.ma_mon_hoc" => ma_mon).first
  	end
  end
  has_many :diem_chi_tiets, :foreign_key => 'ma_sinh_vien', :primary_key => 'ma_sinh_vien', :dependent => :destroy do 
    def diemkiemtra(ma_lop, ma_mon, lan)
      where("diem_chi_tiets.ma_lop" => ma_lop, "diem_chi_tiets.ma_mon_hoc" => ma_mon, "lan" => lan, "loai_diem" => "1")
    end
    def diemthuchanh(ma_lop, ma_mon)
      where("diem_chi_tiets.ma_lop" => ma_lop, "diem_chi_tiets.ma_mon_hoc" => ma_mon, "loai_diem" => "2")
    end
  end

  has_many :diem_danhs, :foreign_key => 'ma_sinh_vien', :primary_key => 'ma_sinh_vien', :dependent => :destroy do 
  	def with_lop(ma_lop)
  		where("diem_danhs.ma_lop" => ma_lop)
  	end    
  end
  def thong_tin_diem_danh(ma_lop, ngay_vang)
    res  = DiemDanh.by_lop_sinhvien_ngay(ma_lop, self.ma_sinh_vien, ngay_vang)
    if res.empty? then return  0 
    else return res.first.so_tiet_vang end
  end
  def fullname
    if self.ho_dem
      self.ho_dem + self.ten 
    else
      self.ten
    end
  end 
  def tbkt(ma_lop, ma_mon)
    diem_chi_tiets.with_lop(ma_lop, ma_mon, [1,2,3],"1").average('diem')
  end
  def diemthuchanh(ma_lop, ma_mon)
    diem_chi_tiets(ma_lop, ma_mon, [1,2,3],"2").average('diem')
  end
  def diem_chuyen_can(ma_lop, ma_mon)
    diem_chuyen_cans.with_lop(ma_lop, ma_mon).try(:diem) || 0
  end
  def diem_qua_trinh(ma_lop, ma_mon)
        
  end
  def lop_mon_hocs
    l1 = self.lop_mon_hoc_sinh_viens.map {|t| t and t.lop_mon_hoc }
    l2 = self.lop_mon_hoc_sinh_viens.map {|t| t and t.lop_ghep and t.lop_ghep.lop_mon_hoc }
    return (l1 + l2).select {|t| t != nil}
  end

  def get_tkbs
    l1 = self.lop_mon_hoc_sinh_viens.map {|t| t and t.lop_mon_hoc }
    l2 = self.lop_mon_hoc_sinh_viens.map {|t| t and t.lop_ghep and t.lop_ghep.lop_mon_hoc }
    lops = (l1 + l2).select {|t| t != nil}
    tkbs = []
    lops.each do |l|
      tkbs = tkbs + l.tkb_giang_viens
    end
    return tkbs
  end
  def get_days
    ngays = []
    tkbs = get_tkbs
    return nil if tkbs.empty?
    get_tkbs.each do |tkb|
      ngay = JSON.parse(tkb.days)["ngay"]
      ngays = ngays + ngay
    end
    ngays = ngays.sort_by {|h| [h["tuan"], h["time"]]}
    return {:ngay => ngays}
  end
end
