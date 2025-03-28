import axios from 'axios';
import {IProductionToolResponse} from '@src/Tools/Production/IProductionToolResponse';
import {IProductionDataApiRequest} from '@src/Tools/Production/IProductionData';

export class Solver
{

	public static solveProduction(productionRequest: IProductionDataApiRequest, callback: (response: IProductionToolResponse) => void): void
	{
		axios({
			method: 'post',
			url: 'https://api.satisfactorytools.com/v2/solver',
			data: productionRequest,
		}).then((response) => {
			if ('result' in response.data) {
				callback(response.data.result);
			}
		}).catch(() => {
			callback({});
		});
	}

}
