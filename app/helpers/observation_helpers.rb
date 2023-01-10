class ApiService < Sinatra::Base

	def get_unit(code, unit)
		case code
		when ObservationCode::CIRCUMFERENCE_PERCENTILE
			'%'
		when ObservationCode::BMI_PERCENTILE 
			'%'
		when ObservationCode::RESPIRATORY_RATE
			'/min'
		when ObservationCode::HEART_RATE
			'/min'
		when ObservationCode::PEDIATRIC_WEIGHT_FOR_HEIGHT
			'%'
		else
			unit
		end			
	end
end