require "rails_helper"

RSpec.describe "Appointment Managment", type: :request do
  let!(:client) { FactoryGirl.create(:client) }
  let!(:appt)   { FactoryGirl.create(:appointment, client: client, time: Date.today) }

  let (:response_json) { JSON.parse(response.body, symbolize_names: true) }

  describe 'index' do
    it 'Retrieves all appointments' do
      get "/api/appointments.json"

      expect(response_json[:appointments].first).to include(id: appt.id)
      expect(response_json[:clients].first).to include(id: client.id)
    end
  end

  describe 'show' do
    it 'Retrieves an appointment' do
      get "/api/appointments/#{appt.id}.json"

      expect(response_json[:appointment]).to include(id: appt.id)
      expect(response_json[:client]).to include(id: client.id)
    end
  end

  describe 'today' do
    let!(:yesterday) { FactoryGirl.create(:appointment, client: client, time: Date.today - 1) }
    let!(:today)     { appt }
    let!(:tomorrow)  { FactoryGirl.create(:appointment, client: client, time: Date.today + 1) }

    it 'fetches appointments for today' do
      get '/api/appointments/today.json'

      expect(response_json[:appointments].count).to eq 1
      expect(response_json[:appointments].first[:id]).to eq today.id
      expect(response_json[:clients].first[:id]).to eq client.id
      expect(response_json[:notes]).to be_empty
    end
  end

  describe 'create' do
    let(:appointment_params) {{
      client_id: client.id,
      time: DateTime.new(2017, 5, 5),
      usda_qualifier: false,
      num_children: 12,
      num_adults: 15,
      appointment_type: %w(food)
    }}

    it 'Creates a new appointment' do
      expect {
        post "/api/appointments.json", params: { appointment: appointment_params }
      }.to change(Appointment, :count).by(1)
    end

    it 'Returns a 400 when errors occur' do
      incomplete_params = appointment_params.merge(client_id: nil)

      expect(
        post "/api/appointments.json", params: { appointment: incomplete_params }
      ).to equal(400)
    end

    it 'Handles errors' do
      incomplete_params = appointment_params.merge(client_id: nil)

      post "/api/appointments.json", params: { appointment: incomplete_params }

      expect(response_json).to have_key(:errors)
    end
  end

  describe 'update' do
    it 'successfully updates appt' do
      current_num_adults = appt.num_adults
      current_num_children = appt.num_children
      put "/api/appointments/#{appt.id}.json", params: {appointment: {num_adults: current_num_adults * 2, num_children: current_num_children * 2}}
      expect(appt.reload.num_adults).to eql(current_num_adults * 2)
      expect(appt.reload.num_children).to eql(current_num_children * 2)
    end

    describe 'does not allow client_id to be changed' do
      let(:other_client) { FactoryGirl.create(:client) }

      before do
        put "/api/appointments/#{appt.id}.json", params: {appointment: {client_id: other_client.id}}
      end

      it "does not change the client id" do
        expect(appt.reload.client_id).to eql(client.id)
      end

      it "returns errors" do
        expect(response_json).to have_key(:errors)
      end
    end
  end

  describe 'delete' do
    it 'successfully deletes an appointment' do
      delete "/api/appointments/#{appt.id}"
      expect(Appointment.exists?(appt.id)).to be(false)
      expect(response).to be_success
    end

    it 'renders errors json with 404 if not found' do
      delete "/api/appointments/0"
      expect(response_json).to have_key(:errors)
      expect(response).to be_not_found
    end
  end
end
