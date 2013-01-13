class Call < ActiveRecord::Base

	reportable :hourly, :aggregation => :count, :grouping => :hour, :live_data => true, :cacheable => false, :limit => 24
	reportable :daily, :aggregation => :count, :grouping => :day, :live_data => true, :cacheable => false, :limit => 7
	reportable :weekly, :aggregation => :count, :grouping => :week, :live_data => true, :cacheable => false, :limit => 52
	reportable :monthly, :aggregation => :count, :grouping => :month, :live_data => true, :cacheable => false, :limit => 12

	reportable :analyzed_hourly, :aggregation => :count, :grouping => :hour, :date_column => :analysis_completed_at, :live_data => true, :cacheable => false, :limit => 24
	reportable :analyzed_daily, :aggregation => :count, :grouping => :day, :date_column => :analysis_completed_at, :live_data => true, :cacheable => false, :limit => 7
	reportable :analyzed_weekly, :aggregation => :count, :grouping => :week, :date_column => :analysis_completed_at, :live_data => true, :cacheable => false, :limit => 52
	reportable :analyzed_monthly, :aggregation => :count, :grouping => :month, :date_column => :analysis_completed_at, :live_data => true, :cacheable => false, :limit => 12

	belongs_to :project
	belongs_to :provider
	belongs_to :job
	has_one :call_medium, :dependent => :delete

	has_many :matches, :class_name => 'Call', :finder_sql => proc {
		'SELECT calls.*,  ' +
		"	(( icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[] & calls.fprint::int[]) / icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}'::int[])::float ) * 100.0 ) AS matchscore " +
		'FROM calls ' +
		'WHERE icount(calls.fprint) > 0 AND ' +
		"calls.job_id = \'#{job_id}\' AND " +
		"calls.id != \'#{id}\' " +
#		"AND (( icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[] & calls.fprint::int[]) / icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}'::int[])::float ) * 100.0 ) > 10.0 " +
		'ORDER BY matchscore DESC'
	}

	has_many :matches_all_jobs, :class_name => 'Call', :finder_sql => proc {
		'SELECT calls.*,  ' +
		"	(( icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[] & calls.fprint::int[]) / icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[])::float ) * 100.0 ) AS matchscore " +
		'FROM calls ' +
		'WHERE icount(calls.fprint) > 0 AND ' +
		"calls.id != \'#{id}\' " +
#	"AND (( icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[] & calls.fprint::int[]) / icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}'::int[])::float ) * 100.0 ) > 10.0 " +
		'ORDER BY matchscore DESC'
	}


	after_save :update_linked_line

	def paginate_matches(scope, min_match, page, per_page)

		scope_limit = ""
		case scope
		when 'job'
			scope_limit = "calls.job_id = \'#{job_id}\' AND "
		when 'project'
			scope_limit = "calls.project_id = \'#{project_id}\' AND "
		end

		query =
			'SELECT calls.*,  ' +
			"	(( icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[] & calls.fprint::int[]) / icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}'::int[])::float ) * 100.0 ) AS matchscore " +
			'FROM calls ' +
			'WHERE icount(calls.fprint) > 0 AND ' +
			scope_limit +
			"calls.id != \'#{id}\' " +
			"AND (( icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}\'::int[] & calls.fprint::int[]) / icount(\'{#{fprint.map{|x| x.to_s}.join(",")}}'::int[])::float ) * 100.0 ) > #{min_match} " +
			'ORDER BY matchscore DESC'

		Call.paginate_by_sql(query, :page => page, :per_page => per_page)
	end

	def media
		CallMedium.find_or_create_by_call_id_and_project_id(self[:id], self[:project_id])
	end

	def media_fields
		CallMedium.columns_hash.keys.reject{|x| x =~ /^id|_id$/}
	end

	def linked_line
		Line.find_or_create_by_number_and_project_id(self[:number], self[:project_id])
	end

	def update_linked_line
		line = linked_line

		if self[:line_type]
			line.line_type = self[:line_type]
			line.save
		end
	end

end
