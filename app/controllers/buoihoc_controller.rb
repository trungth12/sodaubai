#encoding: utf-8
require 'date'
require 'json'

class BuoihocController < ApplicationController
  include BuoihocHelper
  before_filter :load_lop
  
  def show
    raise ActiveRecord::RecordNotFound unless @lich
  	authorize! :read, @lich
  	
    if @lich 
      @svs = @lop_mon_hoc.lop_mon_hoc_sinh_viens
      @ids = @svs.map{|sv| sv.ma_sinh_vien}
      @lichs = @lop_mon_hoc.lich_trinh_giang_days.where('char_length(noi_dung_day) > 0').order('ngay_day, tuan')
      if @lich.voters
        voters = JSON.parse(@lich.voters) 
        @theme = voters[@type.ma_sinh_vien] if @type.is_a?(SinhVien)
      end

      #@idv = @lich.diem_danhs.select{|t| t and t.so_tiet_vang and t.so_tiet_vang > 0}.map { |k| k.ma_sinh_vien}
      @idv = @lich.diem_danhs.vang.map {|k| k.ma_sinh_vien}
      @svvang = @svs.select {|k| @idv.include?(k.ma_sinh_vien)}
           
      @svs2 = @svs.each_slice(4)    
      

    end    
    QC.enqueue "GoogleAnalytic.perform", {:category => "Buoihoc", :action => "show", :label => "#{current_user.username}", :value => "1"}.to_json
    respond_to do |format|     
      if @lop_mon_hoc.da_day_xong
        format.html {render :show2}        
      end
      if can? :manage, @lich
        format.html {render :show}        
      elsif can? :read, @lich 
        format.html {render :show_sv}                  
      end      
    end
  end
  def update    
    begin    
      raise ActiveRecord::RecordNotFound unless @lich
      authorize! :manage, @lich
      authorize! :diemdanh, @lich
      if params[:buoihoc]
        @lichtrinh = params[:buoihoc]                  
        @phong = @lichtrinh[:phong].to_s        
      end
      if params[:tiet_nghi]
        @tietnghis = params[:tiet_nghi][@lich.id.to_s]
        if @tietnghis
          @sotietday = @lich.so_tiet_day - @tietnghis.count
          @lich.tiet_nghi = @tietnghis.keys.join(",")
        end        
      else
        @lich.tiet_nghi = nil
        @sotietday = @lich.so_tiet_day
      end
      if (@sotietday and @sotietday > 0 and @buoihoc and @sotietday <= @buoihoc["so_tiet"]) or (@sotietday and @sotietday > 0 and @sotietday <= @lich.so_tiet_day and @lich and (@lich.loai == 5 or @lich.loai == 2) and @lich.status == 3)
        @lich.so_tiet_day_moi = @sotietday
        @lich.phong_moi = @phong if @phong
        @lich.nguoi_tao = current_user
        @svs = @lop_mon_hoc.lop_mon_hoc_sinh_viens
        @ids = @svs.map {|k| k.ma_sinh_vien}

        if params[:msv]
          params[:msv].each do |k, v|
            dd = @lich.diem_danhs.where(ma_sinh_vien: k).first_or_create!     
               
            if dd.so_tiet_vang.nil? or (dd.so_tiet_vang and dd.so_tiet_vang == 0)
              dd.so_tiet_vang = @sotietday
              dd.phep = false                   
            else              
              if dd.so_tiet_vang and dd.so_tiet_vang > @sotietday then
                dd.so_tiet_vang = @sotietday 
                #dd.create_activity key: 'diem_danh.update', owner: dd.sinh_vien                
              end
            end
            dd.create_activity key: 'diem_danh.diemdanh', params: {sotietvang: dd.so_tiet_vang, phep: dd.phep, note: dd.note}, recipient: dd.sinh_vien, owner: current_user
            dd.save! 
          end
          @kovang = @ids - params[:msv].keys
          dds = @lich.diem_danhs.where(ma_sinh_vien: @kovang)
          if dds.count > 0
            dds.each do |dd|
              
              dd.so_tiet_vang = 0
              dd.phep = false
              dd.save!
            end
          end
        else
          dds = @lich.diem_danhs.where(ma_sinh_vien: @ids)
          if dds.count > 0
            dds.each do |dd|
              
              dd.so_tiet_vang = 0
              dd.phep = false
              dd.save!
            end
          end
        end
        @svs = @lop_mon_hoc.lop_mon_hoc_sinh_viens

        @idv = @lich.diem_danhs.vang.map { |k| k.ma_sinh_vien}
        @svvang = @svs.select {|k| @idv.include?(k.ma_sinh_vien)}
        @kovang = @svs.select {|k| !@idv.include?(k.ma_sinh_vien)}
        if params[:buoihoc]
          @lichtrinh = params[:buoihoc]                
          @lich.noi_dung_day = @lichtrinh[:noidung]
          @lich.so_vang = @svvang.count
          @lich.create_activity key: "lich_trinh_giang_day.update", params: {sovang: @lich.so_vang}, owner: current_user
          @lich.save! rescue "error save lich trinh"
        end
        
      else
        @error = true
        @msg = "Số tiết dạy không hợp lệ"  
      end      
      QC.enqueue "GoogleAnalytic.perform", {:category => "Buoihoc", :action => "update", :label => "#{current_user.username}", :value => "1"}.to_json
      respond_to do |format|     
        format.js      
      end
    rescue Exception => e
      logger.debug "ERROR #{e}"
      respond_to do |format|     
        format.js      
      end
    end
  end
  def rate
    raise ActiveRecord::RecordNotFound unless @lich
    authorize! :rate, @lich    
    if @lich             
      if params[:theme].to_i >= 0 and params[:theme].to_i <= 5 then 
        voters = (JSON.parse(@lich.voters) if @lich.voters) || {}
        voters[@type.ma_sinh_vien] = params[:theme].to_i
        @lich.voters = voters.to_json
        @lich.rating_score = 0 
        @lich.ratings = 0 
        @lich.ratings = voters.keys.count
        voters.each do |k,v|
          @lich.rating_score += v 
        end
        @lich.save! rescue puts "error"
      else
        @error = "Đã có lỗi xảy ra"
      end
    end    
    QC.enqueue "GoogleAnalytic.perform", {:category => "Buoihoc", :action => "rate", :label => "#{current_user.username}", :value => "1"}.to_json
    respond_to do |format|
      format.js
    end
  end
  def diemdanh
    begin
      raise ActiveRecord::RecordNotFound unless @lich
      authorize! :manage, @lich
      authorize! :diemdanh, @lich
      if params[:buoihoc]
        @lichtrinh = params[:buoihoc]                  
        @phong = @lichtrinh[:phong].to_s        
      end
      if params[:tiet_nghi]
        @tietnghis = params[:tiet_nghi][@lich.id.to_s]
        if @tietnghis
          @sotietday = @lich.so_tiet_day - @tietnghis.count
          @lich.tiet_nghi = @tietnghis.keys.join(",")
        end        
      else
        @lich.tiet_nghi = nil
        @sotietday = @lich.so_tiet_day
      end
      if @sotietday > 0 and @buoihoc and @sotietday <= @buoihoc["so_tiet"]
        @lich.so_tiet_day_moi = @sotietday if @sotietday
        @lich.phong_moi = @phong if @phong
        @lich.nguoi_tao = current_user
        params[:msv].each do |k,v|
          dd = @lich.diem_danhs.where(ma_sinh_vien: k).first
          dd = @lich.diem_danhs.where(ma_sinh_vien: k).create if !dd and (v[:sotiet].to_i > 0 or !v[:note].blank?)
          if dd            
            st = v[:sotiet].to_i
            if st and st >=0 and st <= @buoihoc["so_tiet"]
              dd.so_tiet_vang = st if st >= 0 and st <= @sotietday              
              dd.so_tiet_vang = @sotietday if (dd.so_tiet_vang and dd.so_tiet_vang > @sotietday)
              
              dd.phep = (v[:phep] and st > 0) ? true : false
              dd.note = v[:note] unless v[:note].blank?
              dd.create_activity key: 'diem_danh.diemdanh', params: {sotietvang: dd.so_tiet_vang, phep: dd.phep}, recipient: dd.sinh_vien, owner: current_user
              dd.save! rescue "Error save"
            else
              @errorsv ||= []
              @errorsv << k              
            end
          end
        end
      else 
        @error = true
      end
      @svs = @lop_mon_hoc.lop_mon_hoc_sinh_viens
      
      @idv = @lich.diem_danhs.vang.map { |k| k.ma_sinh_vien}
      @svvang = @svs.select {|k| @idv.include?(k.ma_sinh_vien)}
      @kovang = @svs.select {|k| !@idv.include?(k.ma_sinh_vien)}
      
      
      @lich.so_vang =  @svvang.count
      @lich.save!      
      QC.enqueue "GoogleAnalytic.perform", {:category => "Buoihoc", :action => "diemdanh", :label => "#{current_user.username}", :value => "1"}.to_json
      respond_to do |format|
        format.js
      end
    rescue Exception => e
      puts e
    end
  end
  
  def get_diemdanh
    raise ActiveRecord::RecordNotFound unless @lich
    authorize! :read, @lich
    @svs = @lop_mon_hoc.lop_mon_hoc_sinh_viens    
    @idv = @lich.diem_danhs.vang.map { |k| k.ma_sinh_vien}
    @svvang = @svs.select {|k| @idv.include?(k.ma_sinh_vien)}    
    QC.enqueue "GoogleAnalytic.perform", {:category => "Buoihoc", :action => "get_diemdanh", :label => "#{current_user.username}", :value => "1"}.to_json
    respond_to do |format|
      if @lop_mon_hoc.da_day_xong
        format.html {render :diemdanh2}
      end
      if can? :manage, @lich
        format.html {render :diemdanh}        
      elsif can? :read, @lich
        format.html {render :diemdanh_sv}                
      end
              
    end
  end

  def nghiday
    raise ActiveRecord::RecordNotFound unless @lich
    authorize! :manage, @lich
    authorize! :quanly, @lich    
    if params[:buoihoc] and params[:buoihoc][:nghiday]
      @lich.loai = 1
      @lich.status = 6
      @lich.note = params[:buoihoc][:note] if params[:buoihoc][:note]
      @lich.save!
    else
      @lich.loai = nil
      @lich.status = nil
      @lich.note = nil
      @lich.save!
    end    
    QC.enqueue "GoogleAnalytic.perform", {:category => "Buoihoc", :action => "nghiday", :label => "#{current_user.username}", :value => "1"}.to_json
    respond_to do |format|
      format.js
    end
  end

  def daybu
    begin
      raise ActiveRecord::RecordNotFound unless @lich
      authorize! :manage, @lich
      authorize! :quanly, @lich
      if params[:buoihoc][:ngay] and params[:buoihoc][:thang] and params[:buoihoc][:nam]
        @tiet = params[:buoihoc][:tiet]
        t = LichTrinhGiangDay::TIET[@tiet.to_i]
        thoigian = params[:buoihoc][:nam] + "-" + params[:buoihoc][:thang] + "-" + params[:buoihoc][:ngay] + "-" + t[0].to_s + "-" + t[1].to_s
        @ngaybu = str_to_ngay(thoigian) 
        @lich.ngay_day_moi = get_ngay(@ngaybu)      
        @lich.tuan_moi = LichTrinhGiangDay.current_tuan(@lich.ngay_day_moi.localtime)
        gv = @lich.lop_mon_hoc.giang_vien 
        if gv and !gv.check_conflict(@lich.ngay_day_moi.localtime)  
          @lich.loai = 2
          @lich.status = 6          
          @lich.save!          
        else
          @error = 1           
        end
        
      else
        @lich.loai = nil
        @lich.status = nil
        @lich.ngay_day_moi = nil
        @lich.note = nil
        @lich.save!
      end      
      QC.enqueue "GoogleAnalytic.perform", {:category => "Buoihoc", :action => "daybu", :label => "#{current_user.username}", :value => "1"}.to_json
      respond_to do |format|
        format.js
      end
    rescue Exception => e 
      logger.debug "ERROR #{e}"
      respond_to do |format|
        format.js
      end
    end
  end

  def daythay    
    raise ActiveRecord::RecordNotFound unless @lich
    authorize! :manage, @lich
    authorize! :quanly, @lich
    
    respond_to do |format|
      format.js
    end
  end
  def doigio    
    raise ActiveRecord::RecordNotFound unless @lich
    authorize! :manage, @lich
    authorize! :quanly, @lich

    ma_giang_vien_moi = params[:giohoc][:magiangvien]
    thoigian = params[:giohoc][:thoigian]

    unless thoigian.empty?
      tg = thoigian.split(",").to_a 
      tuan = tg[0]
      ngay = tg[1]
      sotiet = tg[2]
      ma_mon = tg[3]
      ten_mon = tg[4]
      ma_lop = tg[5]

      l = LopMonHoc.where(ma_lop: ma_lop, ma_mon_hoc: ma_mon).first
      @lich.update_attributes(loai: 4, status: 1, ma_giang_vien_moi: ma_giang_vien_moi, ngay_day_moi: get_ngay(str_to_ngay(ngay)), tuan_moi: tuan, so_tiet_day_moi: sotiet, ma_mon_hoc_moi: ma_mon, ten_mon_hoc_moi: ten_mon)      
      @lich.lop_bo_sung = l if l 
      @lich.save! rescue @error = true
    end

    respond_to do |format|
      format.js
    end
  end
  def calendar
    raise ActiveRecord::RecordNotFound unless @lich
    authorize! :manage, @lich
    authorize! :quanly, @lich

    gv = params[:doigio][:magiangvien]
    @gv = GiangVien.where(ma_giang_vien: gv).first
    if @gv          
      @current_lops = @gv.lop_mon_hocs.where(ma_lop: @lop_mon_hoc.ma_lop)
      
      @calendar = @gv.get_days[:ngay].uniq if @gv.get_days
      
      generator = ColorGenerator.new saturation: 0.3, lightness: 0.75
      @color = [] 
      20.times do |i|
        @color << generator.create_hex
      end
      @color_map = {}
      unless @current_lops.empty?
        @current_lops.each_with_index do |l,i|
          @color_map["#{l.ma_mon_hoc}"] = @color[i] if l 
        end           
      end
    else
      @current_lops = []
    end
    respond_to do |format|
      format.js
    end
  end
  def get_quanly    
    raise ActiveRecord::RecordNotFound unless @lich
    authorize! :manage, @lich
    @lops = LopMonHoc.where(ma_lop: @lop_mon_hoc.ma_lop).reject {|it| it.id == @lop_mon_hoc.id or it.ma_giang_vien == @lop_mon_hoc.ma_giang_vien}
    @gvs = GiangVien.all.uniq {|gv| gv.ma_giang_vien }.reject {|it| it.ma_giang_vien == @lop_mon_hoc.ma_giang_vien}    
    QC.enqueue "GoogleAnalytic.perform", {:category => "Buoihoc", :action => "get_quanly", :label => "#{current_user.username}", :value => "1"}.to_json
    respond_to do |format|
      format.html {render :quanly}
    end
  end

  protected

  def to_zdate(str)
    DateTime.strptime(str.gsub("T","-").gsub("Z",""), "%Y-%m-%d-%H:%M").change(:offset => Rational(7,24))
  end
  def from_zdate(str)
    str1 = str.split("-").to_a
     str2 = str1[0]+"-"+str1[1]+"-"+str1[2]+"T"+str1[3]+":"+str1[4]+":00Z"
     return str2
  end
  def load_lop
  	@lop_mon_hoc = LopMonHoc.find(params[:lop_mon_hoc_id])  
    @trucnhat = JSON.parse(@lop_mon_hoc.trucnhat) if @lop_mon_hoc.trucnhat

    @pid = params[:id]
    @ngay = str_to_ngay(params[:id])
    @tuan = get_tuan(@ngay).stt
    @malop = @lop_mon_hoc.ma_lop
    @mamonhoc = @lop_mon_hoc.ma_mon_hoc
    @magiangvien = @lop_mon_hoc.ma_giang_vien
    @role = current_user.role
    @type = current_user.imageable
    if @type.is_a?(GiangVien)  then 
      @ngayhoc = @type.get_days[:ngay]
      #@tkb = @type.tkb_giang_viens.with_lop(@malop, @mamonhoc, @tuan).first
      @buoihoc = @ngayhoc.select {|l| l["tuan"] == @tuan and to_zdate(l["time"][0]) == @ngay}[0] if @ngayhoc
      @lich = @lop_mon_hoc.lich_trinh_giang_days.where(ngay_day: get_ngay(@ngay)).first_or_create!        
      if @lich.so_tiet_day_moi.nil? or @lich.phong_moi.nil?
        @lich.so_tiet_day = @buoihoc["so_tiet"] if @buoihoc 
        @lich.so_tiet_day_moi = @buoihoc["so_tiet"] if @buoihoc      
        @lich.phong_moi = @buoihoc["phong"] if @buoihoc
        @lich.save!
      end
      @nhomtruc = @trucnhat[from_zdate(@pid)] if @trucnhat
    elsif @type.is_a?(SinhVien)
      @ngayhoc = @type.get_days[:ngay]
      #@tkb = @type.get_tkbs.select {|k| k[:tuan_hoc_bat_dau] <= @tuan and k[:ma_lop] == @malop and k[:ma_mon_hoc] == @mamonhoc}.first
      @buoihoc = @ngayhoc.select {|l| l["tuan"] == @tuan and  to_zdate(l["time"][0]) == @ngay}[0] if @ngayhoc
      @lich = @lop_mon_hoc.lich_trinh_giang_days.where(ngay_day: get_ngay(@ngay)).first
      @nhomtruc = @trucnhat[from_zdate(@pid)] if @trucnhat
    elsif @role == 'trogiang'  
      @type = current_user    
      @ngayhoc = @type.get_days[:ngay] if @type.get_days
      #@tkb = @type.get_tkbs.select {|k| k[:tuan_hoc_bat_dau] <= @tuan and  k[:ma_lop] == @malop and k[:ma_mon_hoc] == @mamonhoc}.first
      @buoihoc = @ngayhoc.select {|l| l["tuan"] == @tuan and  to_zdate(l["time"][0]) == @ngay}[0] if @ngayhoc
      @lich = @lop_mon_hoc.lich_trinh_giang_days.where(ngay_day: get_ngay(@ngay)).first_or_create! 
      if @lich.so_tiet_day_moi.nil? or @lich.phong_moi.nil?
        @lich.so_tiet_day = @buoihoc["so_tiet"] if @buoihoc 
        @lich.so_tiet_day_moi = @buoihoc["so_tiet"] if @buoihoc      
        @lich.phong_moi = @lop_mon_hoc.phong_hoc
        @lich.nguoi_tao = current_user
        @lich.save!
      end
      @nhomtruc = @trucnhat[from_zdate(@pid)] if @trucnhat
    end       
    if current_user.is_admin?
      @type = @lop_mon_hoc.giang_vien
      @ngayhoc = @type.get_days[:ngay]
      #@tkb = @type.tkb_giang_viens.with_lop(@malop, @mamonhoc, @tuan).first
      @buoihoc = @ngayhoc.select {|l| l["tuan"] == @tuan and  to_zdate(l["time"][0]) == @ngay}[0] if @ngayhoc
      @lich = @lop_mon_hoc.lich_trinh_giang_days.where(ngay_day: get_ngay(@ngay)).first_or_create!        
      if @lich.so_tiet_day_moi.nil? or @lich.phong_moi.nil?
        @lich.so_tiet_day = @buoihoc["so_tiet"] if @buoihoc 
        @lich.so_tiet_day_moi = @buoihoc["so_tiet"] if @buoihoc      
        @lich.phong_moi = @lop_mon_hoc.phong_hoc
        @lich.nguoi_tao = current_user
        @lich.save!
      end
      @nhomtruc = @trucnhat[from_zdate(@pid)] if @trucnhat
    end
  end

end
